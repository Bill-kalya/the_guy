# Service Quality Score (SQS) Implementation Guide

## Overview

This document provides a comprehensive guide for implementing the Service Quality Score (SQS) system for The Guy app. The SQS system replaces traditional star ratings with a more detailed, multi-dimensional scoring system that provides better customer feedback and provider analytics.

## Table of Contents

1. [Architecture](#architecture)
2. [Database Changes](#database-changes)
3. [Backend Implementation](#backend-implementation)
4. [Frontend Implementation](#frontend-implementation)
5. [API Changes](#api-changes)
6. [Migration Strategy](#migration-strategy)

---

## Architecture

### Old System (Star Ratings)
```
Review
 ├── Rating: 4.7
 ├── Comment
```

### New System (SQS)
```
Review
 ├── Overall Experience (0-100)
 ├── Timeliness (0-100)
 ├── Professionalism (0-100)
 ├── Communication (0-100)
 ├── Courtesy (0-100)
 ├── Work Quality (0-100)
 ├── Attention To Detail (0-100)
 ├── Cleanliness (0-100)
 ├── Reliability (0-100)
 ├── Value For Money (0-100)
 ├── Problem Resolution (0-100, optional)
 ├── Recommendation (0-100)
 ├── Comment
 └── Service Quality Score (calculated)
```

### Benefits
- **Better customer feedback**: 12 dimensions vs 1 rating
- **More useful provider analytics**: Category-specific insights
- **Less rating manipulation**: Harder to game multiple dimensions
- **Better provider ranking**: More nuanced matching
- **Better service matching**: Customers can prioritize specific qualities

---

## Database Changes

### Review Table

**Current Schema:**
```sql
CREATE TABLE reviews (
    id UUID PRIMARY KEY,
    provider_id UUID,
    customer_id UUID,
    job_id UUID,
    rating DOUBLE PRECISION,
    comment TEXT,
    created_at TIMESTAMP
);
```

**New Schema:**
```sql
CREATE TABLE reviews (
    id UUID PRIMARY KEY,

    provider_id UUID NOT NULL,
    customer_id UUID NOT NULL,
    job_id UUID NOT NULL,

    overall_experience INTEGER NOT NULL CHECK (overall_experience >= 0 AND overall_experience <= 100),
    timeliness INTEGER NOT NULL CHECK (timeliness >= 0 AND timeliness <= 100),
    professionalism INTEGER NOT NULL CHECK (professionalism >= 0 AND professionalism <= 100),
    communication INTEGER NOT NULL CHECK (communication >= 0 AND communication <= 100),
    courtesy INTEGER NOT NULL CHECK (courtesy >= 0 AND courtesy <= 100),
    work_quality INTEGER NOT NULL CHECK (work_quality >= 0 AND work_quality <= 100),
    attention_to_detail INTEGER NOT NULL CHECK (attention_to_detail >= 0 AND attention_to_detail <= 100),
    cleanliness INTEGER NOT NULL CHECK (cleanliness >= 0 AND cleanliness <= 100),
    reliability INTEGER NOT NULL CHECK (reliability >= 0 AND reliability <= 100),
    value_for_money INTEGER NOT NULL CHECK (value_for_money >= 0 AND value_for_money <= 100),

    problem_resolution INTEGER CHECK (problem_resolution >= 0 AND problem_resolution <= 100),
    recommendation INTEGER NOT NULL CHECK (recommendation >= 0 AND recommendation <= 100),

    service_quality_score DOUBLE PRECISION NOT NULL,

    comment TEXT,

    created_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (provider_id) REFERENCES users(id),
    FOREIGN KEY (customer_id) REFERENCES users(id),
    FOREIGN KEY (job_id) REFERENCES jobs(id)
);

CREATE INDEX idx_reviews_provider ON reviews(provider_id);
CREATE INDEX idx_reviews_job ON reviews(job_id);
CREATE INDEX idx_reviews_customer ON reviews(customer_id);
```

### Provider Statistics Table

**New Table:**
```sql
CREATE TABLE provider_statistics (
    provider_id UUID PRIMARY KEY,

    sqs DOUBLE PRECISION DEFAULT 0,
    professionalism_score DOUBLE PRECISION DEFAULT 0,
    communication_score DOUBLE PRECISION DEFAULT 0,
    timeliness_score DOUBLE PRECISION DEFAULT 0,
    work_quality_score DOUBLE PRECISION DEFAULT 0,
    value_score DOUBLE PRECISION DEFAULT 0,
    reliability_score DOUBLE PRECISION DEFAULT 0,
    courtesy_score DOUBLE PRECISION DEFAULT 0,

    review_count INTEGER DEFAULT 0,

    updated_at TIMESTAMP DEFAULT NOW(),

    FOREIGN KEY (provider_id) REFERENCES users(id)
);

CREATE INDEX idx_provider_statistics ON provider_statistics(provider_id);
```

### Migration Script

```sql
-- Add new columns to users table for SQS
ALTER TABLE users ADD COLUMN IF NOT EXISTS service_quality_score DOUBLE PRECISION DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS score_breakdown JSONB;

-- Migrate existing ratings to SQS (assuming old 5-star ratings)
UPDATE users u
SET
    service_quality_score = COALESCE(
        (SELECT AVG(r.rating * 20) FROM reviews r WHERE r.provider_id = u.id),
        0
    ),
    score_breakdown = jsonb_build_object(
        'professionalism', COALESCE((SELECT AVG(r.rating * 20) FROM reviews r WHERE r.provider_id = u.id), 0),
        'communication', COALESCE((SELECT AVG(r.rating * 20) FROM reviews r WHERE r.provider_id = u.id), 0),
        'timeliness', COALESCE((SELECT AVG(r.rating * 20) FROM reviews r WHERE r.provider_id = u.id), 0),
        'workQuality', COALESCE((SELECT AVG(r.rating * 20) FROM reviews r WHERE r.provider_id = u.id), 0),
        'reliability', COALESCE((SELECT AVG(r.rating * 20) FROM reviews r WHERE r.provider_id = u.id), 0),
        'courtesy', COALESCE((SELECT AVG(r.rating * 20) FROM reviews r WHERE r.provider_id = u.id), 0),
        'value', COALESCE((SELECT AVG(r.rating * 20) FROM reviews r WHERE r.provider_id = u.id), 0)
    );
```

---

## Backend Implementation

### 1. SQS Calculator Component

**File:** `SqsCalculator.java`

```java
@Component
public class SqsCalculator {

    public double calculate(CreateReviewRequest request) {
        List<Integer> scores = new ArrayList<>();

        // Required scores
        scores.add(request.getOverallExperience());
        scores.add(request.getTimeliness());
        scores.add(request.getProfessionalism());
        scores.add(request.getCommunication());
        scores.add(request.getCourtesy());
        scores.add(request.getWorkQuality());
        scores.add(request.getAttentionToDetail());
        scores.add(request.getCleanliness());
        scores.add(request.getReliability());
        scores.add(request.getValueForMoney());
        scores.add(request.getRecommendation());

        // Optional score
        if (request.getProblemResolution() != null) {
            scores.add(request.getProblemResolution());
        }

        return scores.stream()
                .mapToInt(Integer::intValue)
                .average()
                .orElse(0);
    }
}
```

### 2. Review DTO

**File:** `CreateReviewRequest.java`

```java
@Data
public class CreateReviewRequest {

    @NotNull
    private UUID jobId;

    @NotNull
    @Min(0) @Max(100)
    private Integer overallExperience;

    @NotNull
    @Min(0) @Max(100)
    private Integer timeliness;

    @NotNull
    @Min(0) @Max(100)
    private Integer professionalism;

    @NotNull
    @Min(0) @Max(100)
    private Integer communication;

    @NotNull
    @Min(0) @Max(100)
    private Integer courtesy;

    @NotNull
    @Min(0) @Max(100)
    private Integer workQuality;

    @NotNull
    @Min(0) @Max(100)
    private Integer attentionToDetail;

    @NotNull
    @Min(0) @Max(100)
    private Integer cleanliness;

    @NotNull
    @Min(0) @Max(100)
    private Integer reliability;

    @NotNull
    @Min(0) @Max(100)
    private Integer valueForMoney;

    @Min(0) @Max(100)
    private Integer problemResolution;

    @NotNull
    @Min(0) @Max(100)
    private Integer recommendation;

    @Size(max = 500)
    private String comment;
}
```

### 3. Review Entity

**File:** `Review.java`

```java
@Entity
@Table(name = "reviews")
public class Review {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "provider_id", nullable = false)
    private User provider;

    @ManyToOne
    @JoinColumn(name = "customer_id", nullable = false)
    private User customer;

    @ManyToOne
    @JoinColumn(name = "job_id", nullable = false)
    private Job job;

    // SQS Scores
    @Column(nullable = false)
    private Integer overallExperience;

    @Column(nullable = false)
    private Integer timeliness;

    @Column(nullable = false)
    private Integer professionalism;

    @Column(nullable = false)
    private Integer communication;

    @Column(nullable = false)
    private Integer courtesy;

    @Column(nullable = false)
    private Integer workQuality;

    @Column(nullable = false)
    private Integer attentionToDetail;

    @Column(nullable = false)
    private Integer cleanliness;

    @Column(nullable = false)
    private Integer reliability;

    @Column(nullable = false)
    private Integer valueForMoney;

    @Column
    private Integer problemResolution;

    @Column(nullable = false)
    private Integer recommendation;

    @Column(nullable = false)
    private Double serviceQualityScore;

    @Column
    private String comment;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    // Getters and setters...
}
```

### 4. Review Service

**File:** `ReviewService.java`

```java
@Service
@RequiredArgsConstructor
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final SqsCalculator sqsCalculator;
    private final ProviderStatisticsService providerStatisticsService;

    @Transactional
    public Review createReview(UUID customerId, CreateReviewRequest request) {
        // Validate job exists and is completed
        Job job = jobRepository.findById(request.getJobId())
            .orElseThrow(() -> new ResourceNotFoundException("Job not found"));

        if (!job.getStatus().equals(JobStatus.COMPLETED)) {
            throw new IllegalStateException("Can only review completed jobs");
        }

        // Check if review already exists
        if (reviewRepository.existsByJobId(request.getJobId())) {
            throw new IllegalStateException("Job already reviewed");
        }

        // Calculate SQS
        double sqs = sqsCalculator.calculate(request);

        // Create review
        Review review = Review.builder()
            .provider(job.getProvider())
            .customer(customerRepository.findById(customerId).get())
            .job(job)
            .overallExperience(request.getOverallExperience())
            .timeliness(request.getTimeliness())
            .professionalism(request.getProfessionalism())
            .communication(request.getCommunication())
            .courtesy(request.getCourtesy())
            .workQuality(request.getWorkQuality())
            .attentionToDetail(request.getAttentionToDetail())
            .cleanliness(request.getCleanliness())
            .reliability(request.getReliability())
            .valueForMoney(request.getValueForMoney())
            .problemResolution(request.getProblemResolution())
            .recommendation(request.getRecommendation())
            .serviceQualityScore(sqs)
            .comment(request.getComment())
            .build();

        reviewRepository.save(review);

        // Recalculate provider statistics
        providerStatisticsService.recalculate(job.getProvider().getId());

        return review;
    }

    public List<Review> getProviderReviews(UUID providerId) {
        return reviewRepository.findByProviderIdOrderByCreatedAtDesc(providerId);
    }
}
```

### 5. Provider Statistics Service

**File:** `ProviderStatisticsService.java`

```java
@Service
@RequiredArgsConstructor
public class ProviderStatisticsService {

    private final ReviewRepository reviewRepository;
    private final ProviderStatisticsRepository statisticsRepository;

    @Transactional
    public void recalculate(UUID providerId) {
        List<Review> reviews = reviewRepository.findByProviderId(providerId);

        if (reviews.isEmpty()) {
            // Reset statistics
            ProviderStatistics stats = statisticsRepository.findById(providerId)
                .orElse(new ProviderStatistics());
            stats.setProviderId(providerId);
            stats.setSqs(0.0);
            stats.setProfessionalismScore(0.0);
            stats.setCommunicationScore(0.0);
            stats.setTimelinessScore(0.0);
            stats.setWorkQualityScore(0.0);
            stats.setValueScore(0.0);
            stats.setReliabilityScore(0.0);
            stats.setCourtesyScore(0.0);
            stats.setReviewCount(0);
            stats.setUpdatedAt(LocalDateTime.now());
            statisticsRepository.save(stats);
            return;
        }

        // Calculate averages
        double sqs = reviews.stream()
            .mapToDouble(Review::getServiceQualityScore)
            .average()
            .orElse(0);

        double professionalism = reviews.stream()
            .mapToDouble(Review::getProfessionalism)
            .average()
            .orElse(0);

        double communication = reviews.stream()
            .mapToDouble(Review::getCommunication)
            .average()
            .orElse(0);

        double timeliness = reviews.stream()
            .mapToDouble(Review::getTimeliness)
            .average()
            .orElse(0);

        double workQuality = reviews.stream()
            .mapToDouble(Review::getWorkQuality)
            .average()
            .orElse(0);

        double value = reviews.stream()
            .mapToDouble(Review::getValueForMoney)
            .average()
            .orElse(0);

        double reliability = reviews.stream()
            .mapToDouble(Review::getReliability)
            .average()
            .orElse(0);

        double courtesy = reviews.stream()
            .mapToDouble(Review::getCourtesy)
            .average()
            .orElse(0);

        // Update or create statistics
        ProviderStatistics stats = statisticsRepository.findById(providerId)
            .orElse(new ProviderStatistics());

        stats.setProviderId(providerId);
        stats.setSqs(sqs);
        stats.setProfessionalismScore(professionalism);
        stats.setCommunicationScore(communication);
        stats.setTimelinessScore(timeliness);
        stats.setWorkQualityScore(workQuality);
        stats.setValueScore(value);
        stats.setReliabilityScore(reliability);
        stats.setCourtesyScore(courtesy);
        stats.setReviewCount(reviews.size());
        stats.setUpdatedAt(LocalDateTime.now());

        statisticsRepository.save(stats);
    }

    public ProviderStatistics getProviderStatistics(UUID providerId) {
        return statisticsRepository.findById(providerId)
            .orElse(new ProviderStatistics());
    }
}
```

### 6. Provider Statistics Entity

**File:** `ProviderStatistics.java`

```java
@Entity
@Table(name = "provider_statistics")
public class ProviderStatistics {

    @Id
    @Column(name = "provider_id")
    private UUID providerId;

    @Column(nullable = false)
    private Double sqs;

    @Column(name = "professionalism_score", nullable = false)
    private Double professionalismScore;

    @Column(name = "communication_score", nullable = false)
    private Double communicationScore;

    @Column(name = "timeliness_score", nullable = false)
    private Double timelinessScore;

    @Column(name = "work_quality_score", nullable = false)
    private Double workQualityScore;

    @Column(name = "value_score", nullable = false)
    private Double valueScore;

    @Column(name = "reliability_score", nullable = false)
    private Double reliabilityScore;

    @Column(name = "courtesy_score", nullable = false)
    private Double courtesyScore;

    @Column(nullable = false)
    private Integer reviewCount;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    // Getters and setters...
}
```

### 7. Provider Statistics Repository

**File:** `ProviderStatisticsRepository.java`

```java
public interface ProviderStatisticsRepository extends JpaRepository<ProviderStatistics, UUID> {
}
```

---

## Frontend Implementation

### Completed Changes

The Flutter frontend has been updated with the following changes:

#### 1. Models Created
- `lib/features/jobs/models/review_model.dart` - Review and CreateReviewRequest models
- `lib/shared/models/provider_statistics_model.dart` - Provider statistics model
- `lib/shared/models/provider_model.dart` - Updated with SQS fields

#### 2. Utilities Created
- `lib/core/utils/sqs_calculator.dart` - SQS calculation logic

#### 3. Widgets Created
- `lib/shared/widgets/service_quality_score.dart` - SQS display widgets
  - `ServiceQualityScore` - Circular progress indicator
  - `ScoreBreakdownRow` - Individual category score row
  - `ScoreBreakdownList` - List of category scores

#### 4. Screens Updated
- `lib/features/jobs/widgets/review_screen.dart` - New review screen with sliders
- `lib/features/home/widgets/nearby_providers_list.dart` - Updated provider cards
- `lib/features/home/screens/home_screen.dart` - Updated featured providers and testimonials
- `lib/features/provider/presentation/screens/provider_profile_screen.dart` - Added SQS breakdown
- `lib/features/profile/screens/profile_screen.dart` - Updated profile header
- `lib/features/jobs/screens/active_job_screen.dart` - Updated provider info
- `lib/features/jobs/screens/matching_screen.dart` - Updated matched provider display

---

## API Changes

### New Endpoints

#### 1. Create Review
```http
POST /api/reviews
Authorization: Bearer {token}
Content-Type: application/json

{
  "jobId": "uuid",
  "overallExperience": 85,
  "timeliness": 90,
  "professionalism": 95,
  "communication": 88,
  "courtesy": 92,
  "workQuality": 87,
  "attentionToDetail": 90,
  "cleanliness": 85,
  "reliability": 93,
  "valueForMoney": 88,
  "problemResolution": null,
  "recommendation": 95,
  "comment": "Great service!"
}

Response 201:
{
  "id": "uuid",
  "providerId": "uuid",
  "customerId": "uuid",
  "jobId": "uuid",
  "overallExperience": 85,
  "timeliness": 90,
  "professionalism": 95,
  "communication": 88,
  "courtesy": 92,
  "workQuality": 87,
  "attentionToDetail": 90,
  "cleanliness": 85,
  "reliability": 93,
  "valueForMoney": 88,
  "problemResolution": null,
  "recommendation": 95,
  "serviceQualityScore": 90.5,
  "comment": "Great service!",
  "createdAt": "2026-07-07T10:00:00"
}
```

#### 2. Get Provider Statistics
```http
GET /api/providers/{providerId}/statistics
Authorization: Bearer {token}

Response 200:
{
  "providerId": "uuid",
  "serviceQualityScore": 94.2,
  "professionalismScore": 96.5,
  "communicationScore": 93.8,
  "timelinessScore": 88.2,
  "workQualityScore": 95.1,
  "valueScore": 91.3,
  "reliabilityScore": 94.7,
  "courtesyScore": 97.2,
  "reviewCount": 128,
  "updatedAt": "2026-07-07T10:00:00"
}
```

#### 3. Get Provider Reviews
```http
GET /api/providers/{providerId}/reviews
Authorization: Bearer {token}

Response 200:
[
  {
    "id": "uuid",
    "providerId": "uuid",
    "customerId": "uuid",
    "jobId": "uuid",
    "overallExperience": 85,
    "timeliness": 90,
    "professionalism": 95,
    "communication": 88,
    "courtesy": 92,
    "workQuality": 87,
    "attentionToDetail": 90,
    "cleanliness": 85,
    "reliability": 93,
    "valueForMoney": 88,
    "problemResolution": null,
    "recommendation": 95,
    "serviceQualityScore": 90.5,
    "comment": "Great service!",
    "createdAt": "2026-07-07T10:00:00"
  }
]
```

### Updated Endpoints

#### Provider List Response
```json
{
  "id": "uuid",
  "name": "John Doe",
  "category": "Plumbing",
  "rating": 4.8,
  "reviewsCount": 128,
  "serviceQualityScore": 94.2,
  "scoreBreakdown": {
    "professionalism": 96.5,
    "communication": 93.8,
    "timeliness": 88.2,
    "workQuality": 95.1,
    "reliability": 94.7,
    "courtesy": 97.2,
    "value": 91.3
  },
  "distance": 2.5,
  "isOnline": true
}
```

---

## Provider Ranking Logic

### Old Ranking
```sql
ORDER BY rating DESC
```

### New Ranking (Recommended)
```sql
ORDER BY
    distance ASC,
    sqs DESC
```

### Advanced Ranking Formula
```sql
ORDER BY
    (0.40 * (1 - LEAST(distance / 10, 1))) +  -- Distance weight: 40%
    (0.35 * (sqs / 100)) +                     -- SQS weight: 35%
    (0.15 * completion_rate) +                 -- Completion rate: 15%
    (0.10 * response_rate)                     -- Response rate: 10%
    DESC
```

This creates a marketplace where:
- Closest providers appear first
- High-quality providers rise naturally
- Fast responders rank higher
- Reliable providers dominate search results

---

## Migration Strategy

### Phase 1: Database Migration (Week 1)
1. Create new tables (`provider_statistics`)
2. Add new columns to `reviews` table
3. Run migration script to convert existing ratings
4. Backfill provider statistics

### Phase 2: Backend API (Week 2)
1. Implement SQS calculator
2. Update review endpoints
3. Add new statistics endpoints
4. Update provider ranking logic
5. Deploy backend changes

### Phase 3: Frontend (Week 3)
1. Deploy new review screen
2. Update all provider displays
3. Add SQS breakdown views
4. Test all screens

### Phase 4: Testing & Rollout (Week 4)
1. Beta test with small user group
2. Monitor feedback
3. Fix bugs
4. Full rollout

---

## Testing Checklist

### Backend
- [ ] SQS calculator produces correct averages
- [ ] Review creation works with all 12 dimensions
- [ ] Provider statistics recalculate correctly
- [ ] Database constraints prevent invalid scores
- [ ] API responses include all new fields
- [ ] Provider ranking uses SQS

### Frontend
- [ ] Review screen displays all 12 sliders
- [ ] SQS preview updates in real-time
- [ ] ServiceQualityScore widget displays correctly
- [ ] All provider cards show SQS instead of stars
- [ ] Provider profile shows breakdown
- [ ] Testimonials show SQS scores
- [ ] Matching screen shows SQS

---

## Notes

- All scores are on a 0-100 scale (not 0-5)
- SQS is the average of all rated dimensions
- Problem resolution is optional (only shown if problems occurred)
- Provider statistics are cached and recalculated on each new review
- Old star ratings are converted to 0-100 scale (multiply by 20)

---

## Support

For questions or issues, contact the development team.

**Document Version:** 1.0
**Last Updated:** 2026-07-07
- [ ] Remove Testimonials section from HomeScreen
- [ ] Remove How It Works section from HomeScreen
- [ ] Remove Featured Service Providers hardcoded cards from HomeScreen
- [ ] Add “What service do you need?” category selection section before providers list
- [ ] Hide public ServiceQualityScore/SQS percent on provider cards (keep stars + distance + ETA)
- [ ] Run flutter analyze
- [ ] Run widget/app build to confirm no compile errors
- [ ] Production config: set API_URL=https://api.theguy.com (and WS_URL=wss://api.theguy.com if WebSocket is on same host)
- [ ] Production build command example:
      flutter build apk --release --dart-define=IS_PRODUCTION=true --dart-define=API_URL=https://api.theguy.com --dart-define=WS_URL=wss://api.theguy.com



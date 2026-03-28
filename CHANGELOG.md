# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-28)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **ingress:** disable publishService when using publish-status-address ([8831283](https://github.com/brettswift/k8s_nas/commit/8831283a15e590712cb4f04b7d8ed03cc6c9adb8))
* **ingress:** force status updates with publish-status-address ([304f866](https://github.com/brettswift/k8s_nas/commit/304f8667052a7c7e79d3584e30711f7ec96702e7))
* **ingress:** publish stable status address for ingress health ([0dda914](https://github.com/brettswift/k8s_nas/commit/0dda914615fc42cd6b06fab11223da1f8fdfbcec))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** remove RTK from image and GitOps; strip PVC plugin artifacts ([2217ae9](https://github.com/brettswift/k8s_nas/commit/2217ae931538a51860dcd5868da19728db99e71e))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** bash aliases, bat symlink, fix Dockerfile RTK comment ([685ebba](https://github.com/brettswift/k8s_nas/commit/685ebba232fcf86825b21b9dec2868e8ad5eb26e))
* **openclaw:** restore RTK binary and rtk-rewrite GitOps plugin ([995648c](https://github.com/brettswift/k8s_nas/commit/995648c59e9bef6b38e7958538b27ab4511ad6a9))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))
* **openclaw:** track k8s_openclaw.json in git with PVC symlink setup ([7e9c561](https://github.com/brettswift/k8s_nas/commit/7e9c561f0cdb15adcba651d7f43253fc86b0aa04))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-28)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **ingress:** disable publishService when using publish-status-address ([8831283](https://github.com/brettswift/k8s_nas/commit/8831283a15e590712cb4f04b7d8ed03cc6c9adb8))
* **ingress:** force status updates with publish-status-address ([304f866](https://github.com/brettswift/k8s_nas/commit/304f8667052a7c7e79d3584e30711f7ec96702e7))
* **ingress:** publish stable status address for ingress health ([0dda914](https://github.com/brettswift/k8s_nas/commit/0dda914615fc42cd6b06fab11223da1f8fdfbcec))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** remove RTK from image and GitOps; strip PVC plugin artifacts ([2217ae9](https://github.com/brettswift/k8s_nas/commit/2217ae931538a51860dcd5868da19728db99e71e))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK binary and rtk-rewrite GitOps plugin ([995648c](https://github.com/brettswift/k8s_nas/commit/995648c59e9bef6b38e7958538b27ab4511ad6a9))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))
* **openclaw:** track k8s_openclaw.json in git with PVC symlink setup ([7e9c561](https://github.com/brettswift/k8s_nas/commit/7e9c561f0cdb15adcba651d7f43253fc86b0aa04))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-28)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **ingress:** disable publishService when using publish-status-address ([8831283](https://github.com/brettswift/k8s_nas/commit/8831283a15e590712cb4f04b7d8ed03cc6c9adb8))
* **ingress:** force status updates with publish-status-address ([304f866](https://github.com/brettswift/k8s_nas/commit/304f8667052a7c7e79d3584e30711f7ec96702e7))
* **ingress:** publish stable status address for ingress health ([0dda914](https://github.com/brettswift/k8s_nas/commit/0dda914615fc42cd6b06fab11223da1f8fdfbcec))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** remove RTK from image and GitOps; strip PVC plugin artifacts ([2217ae9](https://github.com/brettswift/k8s_nas/commit/2217ae931538a51860dcd5868da19728db99e71e))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))
* **openclaw:** track k8s_openclaw.json in git with PVC symlink setup ([7e9c561](https://github.com/brettswift/k8s_nas/commit/7e9c561f0cdb15adcba651d7f43253fc86b0aa04))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-28)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **ingress:** disable publishService when using publish-status-address ([8831283](https://github.com/brettswift/k8s_nas/commit/8831283a15e590712cb4f04b7d8ed03cc6c9adb8))
* **ingress:** force status updates with publish-status-address ([304f866](https://github.com/brettswift/k8s_nas/commit/304f8667052a7c7e79d3584e30711f7ec96702e7))
* **ingress:** publish stable status address for ingress health ([0dda914](https://github.com/brettswift/k8s_nas/commit/0dda914615fc42cd6b06fab11223da1f8fdfbcec))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** remove RTK from image and GitOps; strip PVC plugin artifacts ([2217ae9](https://github.com/brettswift/k8s_nas/commit/2217ae931538a51860dcd5868da19728db99e71e))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-28)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **ingress:** disable publishService when using publish-status-address ([8831283](https://github.com/brettswift/k8s_nas/commit/8831283a15e590712cb4f04b7d8ed03cc6c9adb8))
* **ingress:** force status updates with publish-status-address ([304f866](https://github.com/brettswift/k8s_nas/commit/304f8667052a7c7e79d3584e30711f7ec96702e7))
* **ingress:** publish stable status address for ingress health ([0dda914](https://github.com/brettswift/k8s_nas/commit/0dda914615fc42cd6b06fab11223da1f8fdfbcec))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** remove RTK from image and GitOps; strip PVC plugin artifacts ([2217ae9](https://github.com/brettswift/k8s_nas/commit/2217ae931538a51860dcd5868da19728db99e71e))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-27)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **ingress:** disable publishService when using publish-status-address ([8831283](https://github.com/brettswift/k8s_nas/commit/8831283a15e590712cb4f04b7d8ed03cc6c9adb8))
* **ingress:** force status updates with publish-status-address ([304f866](https://github.com/brettswift/k8s_nas/commit/304f8667052a7c7e79d3584e30711f7ec96702e7))
* **ingress:** publish stable status address for ingress health ([0dda914](https://github.com/brettswift/k8s_nas/commit/0dda914615fc42cd6b06fab11223da1f8fdfbcec))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** remove RTK from image and GitOps; strip PVC plugin artifacts ([2217ae9](https://github.com/brettswift/k8s_nas/commit/2217ae931538a51860dcd5868da19728db99e71e))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-26)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **ingress:** disable publishService when using publish-status-address ([8831283](https://github.com/brettswift/k8s_nas/commit/8831283a15e590712cb4f04b7d8ed03cc6c9adb8))
* **ingress:** force status updates with publish-status-address ([304f866](https://github.com/brettswift/k8s_nas/commit/304f8667052a7c7e79d3584e30711f7ec96702e7))
* **ingress:** publish stable status address for ingress health ([0dda914](https://github.com/brettswift/k8s_nas/commit/0dda914615fc42cd6b06fab11223da1f8fdfbcec))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-26)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **ingress:** disable publishService when using publish-status-address ([8831283](https://github.com/brettswift/k8s_nas/commit/8831283a15e590712cb4f04b7d8ed03cc6c9adb8))
* **ingress:** publish stable status address for ingress health ([0dda914](https://github.com/brettswift/k8s_nas/commit/0dda914615fc42cd6b06fab11223da1f8fdfbcec))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-26)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **ingress:** publish stable status address for ingress health ([0dda914](https://github.com/brettswift/k8s_nas/commit/0dda914615fc42cd6b06fab11223da1f8fdfbcec))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-26)


### Bug Fixes

* **argocd:** manage ingress-nginx with Recreate strategy for hostNetwork ([e82d8ac](https://github.com/brettswift/k8s_nas/commit/e82d8ac55cfd0539d79b5a38115341368a77533d))
* **argocd:** use default project for ingress-nginx Helm chart ([bbd747c](https://github.com/brettswift/k8s_nas/commit/bbd747ceb432bb783365168ebc75dbd8ee109e28))
* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-26)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** restore RTK GitOps plugin; slash CPU requests for home cluster ([baceae4](https://github.com/brettswift/k8s_nas/commit/baceae496721e4f8210d93f3fc4cdf0fffd696a3))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-26)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** ship RTK CLI in image without enabling plugin via GitOps ([670dfa7](https://github.com/brettswift/k8s_nas/commit/670dfa77277544fa1a14463a8f7c16603688bd1d))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-26)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))
* **openclaw:** strip rtk-rewrite from PVC after RTK revert ([91c5e35](https://github.com/brettswift/k8s_nas/commit/91c5e35ac113cf7cf56e9499da33c93b9ffeffe4))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-26)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))
* **openclaw:** install RTK and enable rtk-rewrite plugin ([5da0daa](https://github.com/brettswift/k8s_nas/commit/5da0daa015fa7eb4643871ce5e345c572a185196))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-26)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))


### Performance Improvements

* **k8s:** reduce CPU requests for sabnzbd VPN and background services ([d706dd3](https://github.com/brettswift/k8s_nas/commit/d706dd3fd1787fd5be768e580257566d24bbfc38))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-25)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **monitoring:** do not delete Pending sabnzbd pod (avoid CPU scheduling loop) ([a016fe8](https://github.com/brettswift/k8s_nas/commit/a016fe8732c6305978f1c387071e74c40f27458e))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-25)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))
* **monitoring:** sabnzbd VPN check deletes unhealthy pod + structured logs ([356df86](https://github.com/brettswift/k8s_nas/commit/356df863b25e3def9f51b5140c3d59c197efd71a))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-24)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-18)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** orange for correct driver wrong position in race detail ([808b5f5](https://github.com/brettswift/k8s_nas/commit/808b5f518c9258933d5a773093b130904cb68cf3))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-18)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** race slug URL, points legend, red for winning picks ([066fd76](https://github.com/brettswift/k8s_nas/commit/066fd76ce5f3603d6fc8b7456e357e9e8e484f37))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-18)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **f1:** View button for locked/completed races, race detail page ([fac9a7e](https://github.com/brettswift/k8s_nas/commit/fac9a7ee3c9961bd8fee56bc5c2a127d8249abb4))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-18)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **f1:** race-weekend state machine replacing hourly fetch CronJob ([c678a00](https://github.com/brettswift/k8s_nas/commit/c678a004cce41f19593b2ab527f079f7d74155f6))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-18)


### Bug Fixes

* **f1:** image-refresh poll for new image; release token fallback; build permissions ([0105ecd](https://github.com/brettswift/k8s_nas/commit/0105ecdfeb1ef84fe104d333bc70ffa51d350e80))
* **f1:** Jolpica results API, cron auto-lock, hourly fetch CronJob ([74598b7](https://github.com/brettswift/k8s_nas/commit/74598b75f1c506a9b82018f768354bd10ee20669))


### Features

* **f1:** API-driven data, auto-lock at race start, poll for results ([5376cf5](https://github.com/brettswift/k8s_nas/commit/5376cf5adcd82821ec7ab0387d19a900cccf33cf))
* **f1:** browser auto-retry for race results (replace background thread) ([5a9d3bc](https://github.com/brettswift/k8s_nas/commit/5a9d3bcbc15b5d12ecc509c8146a118bd74ec6f8))
* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-17)


### Features

* **openclaw:** add gateway scopes for cron and operator access ([83502e5](https://github.com/brettswift/k8s_nas/commit/83502e5731429e5e9165db53f188e591a346c12c))
* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

# [1.12.0](https://github.com/brettswift/k8s_nas/compare/v1.11.3...v1.12.0) (2026-03-16)


### Features

* **openclaw:** add python3-pip to custom image, prepare for PVC-based duckdb install ([36e4a3a](https://github.com/brettswift/k8s_nas/commit/36e4a3a9532d10e2242f9f4f2e02226459772ff6))

## [1.11.3](https://github.com/brettswift/k8s_nas/compare/v1.11.2...v1.11.3) (2026-03-16)


### Bug Fixes

* **openclaw:** pin image to 2026.3.13-1 stable; :main build missing plugin-sdk/runtime (breaks Telegram) ([b48e651](https://github.com/brettswift/k8s_nas/commit/b48e651c497a08dff9356d35796f8359578740e4))

## [1.11.2](https://github.com/brettswift/k8s_nas/compare/v1.11.1...v1.11.2) (2026-03-15)


### Bug Fixes

* **openclaw:** disable NetworkPolicy that broke egress (GitOps deploy) ([ffc0a3d](https://github.com/brettswift/k8s_nas/commit/ffc0a3da7c65fe664520fecbb5c24f62c5f8c5de))

## [1.11.1](https://github.com/brettswift/k8s_nas/compare/v1.11.0...v1.11.1) (2026-03-15)


### Bug Fixes

* **openclaw:** use official openclaw image to test egress/network ([8e685f5](https://github.com/brettswift/k8s_nas/commit/8e685f5afebdd46f29fa2773e19ac42b2401cc9a))

# [1.11.0](https://github.com/brettswift/k8s_nas/compare/v1.10.1...v1.11.0) (2026-03-15)


### Features

* **openclaw:** add env-based API key secrets (moonshot, deepseek, notion) for gateway startup ([818a1a4](https://github.com/brettswift/k8s_nas/commit/818a1a4de2394428f0b18d9108bdf9b1ea5e6761))

## [1.10.1](https://github.com/brettswift/k8s_nas/compare/v1.10.0...v1.10.1) (2026-03-15)


### Bug Fixes

* **argocd:** allow NetworkPolicy in apps project for openclaw ([5fdf6ca](https://github.com/brettswift/k8s_nas/commit/5fdf6caf89615545fdc554c334af4e5b045617dc))

# [1.10.0](https://github.com/brettswift/k8s_nas/compare/v1.9.1...v1.10.0) (2026-03-15)


### Bug Fixes

* **openclaw:** add path-based ingress fallback at home.brettswift.com/openclaw ([d17fd1d](https://github.com/brettswift/k8s_nas/commit/d17fd1df67e5a2afc3d2d7b0278ab77adf56b9d8))
* **openclaw:** add proxy-buffering off for WebSocket ([e2d8a13](https://github.com/brettswift/k8s_nas/commit/e2d8a13fdc8c6a4fabceab68ccfd86c5f1110cfa))
* **openclaw:** disable proxy buffering for WebSocket ([b7f6201](https://github.com/brettswift/k8s_nas/commit/b7f6201270bbdcf6ceda567cfa837ddefbdd4589))
* **openclaw:** init container to seed allowedOrigins for path/subdomain access ([09f3557](https://github.com/brettswift/k8s_nas/commit/09f35574ce1aa3c576005ea31437734516befd96))
* **openclaw:** remove configuration-snippet - breaks ingress processing (NGINX_INGRESS_ISSUE) ([59140cc](https://github.com/brettswift/k8s_nas/commit/59140ccfbbc8916c7ffee261c7090e54f7ea9c7b))
* **openclaw:** remove path-based ingress, use subdomain only; clarify token in README ([95e63e5](https://github.com/brettswift/k8s_nas/commit/95e63e59e6b5e0614c06447d6b3b7661e33af479))
* **openclaw:** revert to subdomain openclaw.home.brettswift.com ([1b7f1f1](https://github.com/brettswift/k8s_nas/commit/1b7f1f1ee258bc2ea74d852585c6bf8a21dd3d0c))
* **openclaw:** use native ollama API, remove unused Anthropic/Brave secrets ([b124fc4](https://github.com/brettswift/k8s_nas/commit/b124fc4874b4cfe86a35879540527dcf40981630))
* **openclaw:** use path-based ingress on home.brettswift.com/openclaw for routing ([fe6407a](https://github.com/brettswift/k8s_nas/commit/fe6407ac809b2e0550322cdac26de1c603d5942c))


### Features

* **openclaw:** add Anthropic API key support for chat agent ([615321d](https://github.com/brettswift/k8s_nas/commit/615321da95d6f0eeb6f5d344c55c356adb202a7b))
* **openclaw:** add dedicated ArgoCD Application, remove from infrastructure kustomization ([78c4a80](https://github.com/brettswift/k8s_nas/commit/78c4a803c4024eee0c48fe4636daa4f4a174f4eb))
* **openclaw:** add egress NetworkPolicy - internet and host only, no pod access ([eaa3f91](https://github.com/brettswift/k8s_nas/commit/eaa3f9112da6e5db06185257007aa2f5a6722161))

## [1.9.1](https://github.com/brettswift/k8s_nas/compare/v1.9.0...v1.9.1) (2026-03-14)


### Bug Fixes

* **unpackerr:** add usenet protocol so SABnzbd downloads are processed ([ad6d55f](https://github.com/brettswift/k8s_nas/commit/ad6d55f709cbe7801c243d8fa8c972834681f248))

# [1.9.0](https://github.com/brettswift/k8s_nas/compare/v1.8.1...v1.9.0) (2026-03-14)


### Features

* **media:** deploy Unpackerr with usenet mount for SABnzbd season pack extraction ([dc2a0a9](https://github.com/brettswift/k8s_nas/commit/dc2a0a9bb301e4c5cf0e4bcc3c181d340df361f5))

## [1.8.1](https://github.com/brettswift/k8s_nas/compare/v1.8.0...v1.8.1) (2026-03-13)


### Bug Fixes

* **media:** use Recreate rollout strategy for sabnzbd ([d3dbd61](https://github.com/brettswift/k8s_nas/commit/d3dbd61dcf26f200474b37a060cfb31f1479332c))

# [1.8.0](https://github.com/brettswift/k8s_nas/compare/v1.7.2...v1.8.0) (2026-03-13)


### Features

* **media:** switch sabnzbd VPN from OpenVPN to WireGuard via Gluetun custom provider ([5473124](https://github.com/brettswift/k8s_nas/commit/547312466a770cfa7f85a7471203feff8995d95e))

## [1.7.2](https://github.com/brettswift/k8s_nas/compare/v1.7.1...v1.7.2) (2026-03-13)


### Bug Fixes

* **media:** revert to OpenVPN - Gluetun does not support IPVanish WireGuard ([53987f4](https://github.com/brettswift/k8s_nas/commit/53987f48fa0602dc3aad94665d2ec03e9465ffa5))

## [1.7.1](https://github.com/brettswift/k8s_nas/compare/v1.7.0...v1.7.1) (2026-03-13)


### Bug Fixes

* **media:** remove BBR sysctl - k3s forbids by default, use node-level sysctl instead ([0b0396a](https://github.com/brettswift/k8s_nas/commit/0b0396ade91d022cc734973664d09ee820980f51))

# [1.7.0](https://github.com/brettswift/k8s_nas/compare/v1.6.2...v1.7.0) (2026-03-13)


### Bug Fixes

* **media:** preStop hook on vpn container for clean pod termination during rollout ([68e19e9](https://github.com/brettswift/k8s_nas/commit/68e19e91a95d63c9011db9243430cd3b343e94af))


### Features

* **media:** SABnzbd throughput - WireGuard + BBR (plan 2026-03-12) ([d22bc26](https://github.com/brettswift/k8s_nas/commit/d22bc26e72f408fab42cd9f1343359b4b1b4134d))

## [1.6.2](https://github.com/brettswift/k8s_nas/compare/v1.6.1...v1.6.2) (2026-03-12)


### Bug Fixes

* **monitoring:** VPN check use ipinfo.io without trailing dot so alarm fires when DNS broken ([d1a37fa](https://github.com/brettswift/k8s_nas/commit/d1a37fa16a0762bb422d7bfbbbcad0caf6d47c90))

## [1.6.1](https://github.com/brettswift/k8s_nas/compare/v1.6.0...v1.6.1) (2026-03-12)


### Bug Fixes

* **monitoring:** Sabnzbd VPN alert noDataState OK when healthy ([291d1ba](https://github.com/brettswift/k8s_nas/commit/291d1ba8eef41e39eac93318c3a8b2e76172234c))

# [1.6.0](https://github.com/brettswift/k8s_nas/compare/v1.5.1...v1.6.0) (2026-03-12)


### Features

* **monitoring:** Grafana->ntfy proxy for clean notifications ([dfc5c04](https://github.com/brettswift/k8s_nas/commit/dfc5c04fe74be2f63df5ab649ec778caf10d21a9))

## [1.5.1](https://github.com/brettswift/k8s_nas/compare/v1.5.0...v1.5.1) (2026-03-12)


### Bug Fixes

* **monitoring:** Alarms dashboard - add Sabnzbd VPN alarm panel (matches alert state) ([f92c5f0](https://github.com/brettswift/k8s_nas/commit/f92c5f0a47a0bb00ae0019c5108ca1cde2032924))

# [1.5.0](https://github.com/brettswift/k8s_nas/compare/v1.4.0...v1.5.0) (2026-03-12)


### Features

* **monitoring:** Grafana Sabnzbd VPN alarm, Alarms dashboard, ntfy contact point ([89516e5](https://github.com/brettswift/k8s_nas/commit/89516e5b3f942cd526805964e94cb1be2b77134d))

# [1.4.0](https://github.com/brettswift/k8s_nas/compare/v1.3.3...v1.4.0) (2026-03-10)


### Features

* add list-jellyseerr-requests.sh and re-request-starr.py for Jellyseerr/Sonarr/Radarr ([d412aeb](https://github.com/brettswift/k8s_nas/commit/d412aebfb2e35f0c73ea87e6c07c3d29f0cf1d10))

## [1.3.3](https://github.com/brettswift/k8s_nas/compare/v1.3.2...v1.3.3) (2026-03-10)


### Bug Fixes

* use ipinfo.io. (FQDN) in VPN check so DNS resolves in gluetun container ([ee52e09](https://github.com/brettswift/k8s_nas/commit/ee52e0961bee2eb6183921a63a35f4b07c6f5768))

## [1.3.2](https://github.com/brettswift/k8s_nas/compare/v1.3.1...v1.3.2) (2026-03-10)


### Bug Fixes

* Pushgateway push use PUT + curl (exposition format); image has curl not wget ([c5c6826](https://github.com/brettswift/k8s_nas/commit/c5c68266deb66a47c9911c2e3a7d2a69daefccd5))

## [1.3.1](https://github.com/brettswift/k8s_nas/compare/v1.3.0...v1.3.1) (2026-03-09)


### Bug Fixes

* **vpn:** relax Sabnzbd VPN config, add scripts to update secrets and diagnose ([b1c32a2](https://github.com/brettswift/k8s_nas/commit/b1c32a2155ff7c1f14438f175f5606789dcad765))

# [1.3.0](https://github.com/brettswift/k8s_nas/compare/v1.2.7...v1.3.0) (2026-03-09)


### Features

* **f1:** Add pink DEVELOPMENT banner and remove team from dropdown ([0bfd2c7](https://github.com/brettswift/k8s_nas/commit/0bfd2c7dab5f5cb1b7020c1bb727f1ba3f5d0afe))

## [1.2.7](https://github.com/brettswift/k8s_nas/compare/v1.2.6...v1.2.7) (2026-03-08)


### Bug Fixes

* **f1-predictor:** image-refresh hook Accept header for OCI images ([6858f85](https://github.com/brettswift/k8s_nas/commit/6858f85e08b13d7028b4058d18c13524053865d8))

## [1.2.6](https://github.com/brettswift/k8s_nas/compare/v1.2.5...v1.2.6) (2026-03-08)


### Bug Fixes

* **f1:** add verbose logging to image-refresh hook for GHCR auth debug ([20b80e8](https://github.com/brettswift/k8s_nas/commit/20b80e89e6defe217b1fbd6f71ec69cb10acf490))

## [1.2.5](https://github.com/brettswift/k8s_nas/compare/v1.2.4...v1.2.5) (2026-03-08)


### Bug Fixes

* **f1:** improve image-refresh hook logging - pod digest, registry digest, match status ([ccc626f](https://github.com/brettswift/k8s_nas/commit/ccc626f8c09c1e092155f38e7937cafb0e987c98))

## [1.2.4](https://github.com/brettswift/k8s_nas/compare/v1.2.3...v1.2.4) (2026-03-08)


### Bug Fixes

* **f1:** use GHCR token endpoint with Basic auth for manifest API (private registry) ([06a071e](https://github.com/brettswift/k8s_nas/commit/06a071e6bc2b198d97879e40a6c4df16c3835960))

## [1.2.3](https://github.com/brettswift/k8s_nas/compare/v1.2.2...v1.2.3) (2026-03-08)


### Bug Fixes

* **f1:** use ghcr-pull secret for image-refresh hook (private GHCR); doc sync frequency ([7b5df08](https://github.com/brettswift/k8s_nas/commit/7b5df083c1347d1c4b27fcde8847e1ee03472119))

## [1.2.2](https://github.com/brettswift/k8s_nas/compare/v1.2.1...v1.2.2) (2026-03-08)


### Bug Fixes

* **f1:** image-refresh hook RBAC add pods get/list; log phase/reason when no pod ready ([db343e4](https://github.com/brettswift/k8s_nas/commit/db343e42f0c3ebbb1eda1b25a2674c49287ef8f4))

## [1.2.1](https://github.com/brettswift/k8s_nas/compare/v1.2.0...v1.2.1) (2026-03-08)


### Bug Fixes

* **argocd:** allow Role and RoleBinding in apps project for f1 image-refresh hook ([61bd07b](https://github.com/brettswift/k8s_nas/commit/61bd07bb4653ebb25b5e32fc347426112ba912fe))

# [1.2.0](https://github.com/brettswift/k8s_nas/compare/v1.1.3...v1.2.0) (2026-03-08)


### Features

* **f1:** event-driven image refresh with :dev/:live and PostSync hook ([f64980b](https://github.com/brettswift/k8s_nas/commit/f64980babaceade50de848a55b8588990bea9bfc))

## [1.1.3](https://github.com/brettswift/k8s_nas/compare/v1.1.2...v1.1.3) (2026-03-08)


### Bug Fixes

* **f1:** add external IP target for f1.brettswift.com DNS (NAT'd network) ([397c3e1](https://github.com/brettswift/k8s_nas/commit/397c3e1c7c7a646a8c3b363bd1a2665b3245de5e))

## [1.1.2](https://github.com/brettswift/k8s_nas/compare/v1.1.1...v1.1.2) (2026-03-08)


### Bug Fixes

* **f1:** use sha-required placeholder, never latest/dev - forces ImagePullBackOff until build runs ([abe082e](https://github.com/brettswift/k8s_nas/commit/abe082e0e35f406ea1aa4ed9fe4bc5c98d0b5810))

## [1.1.1](https://github.com/brettswift/k8s_nas/compare/v1.1.0...v1.1.1) (2026-03-08)


### Bug Fixes

* **f1:** only 2 URLs - f1.home (dev, CNAME to home), f1.brettswift.com (prod); remove home subdomain ([b129c3d](https://github.com/brettswift/k8s_nas/commit/b129c3d16ace70ffc55229962b59b43d911283bf))

# [1.1.0](https://github.com/brettswift/k8s_nas/compare/v1.0.4...v1.1.0) (2026-03-08)


### Features

* **f1:** wildcard cert for *.brettswift.com, prod overlay uses it, remove target IP ([079b211](https://github.com/brettswift/k8s_nas/commit/079b2114765d55f308d92a671977a2b48f26ce53))

## [1.0.4](https://github.com/brettswift/k8s_nas/compare/v1.0.3...v1.0.4) (2026-03-08)


### Bug Fixes

* **f1-dev:** add workflow that runs on any f1-dev push (except overlay-only) to set hash ([cbd0702](https://github.com/brettswift/k8s_nas/commit/cbd070240116cd9d28026deaeb8e5a50affa68c1))

## [1.0.3](https://github.com/brettswift/k8s_nas/compare/v1.0.2...v1.0.3) (2026-03-08)


### Bug Fixes

* **f1-dev:** revert to SHA flow - dev overlay placeholder, workflow replaces with hash ([3a965fc](https://github.com/brettswift/k8s_nas/commit/3a965fc8bf77c24dcc5bde223846049cb1772e58))

## [1.0.2](https://github.com/brettswift/k8s_nas/compare/v1.0.1...v1.0.2) (2026-03-08)


### Bug Fixes

* **f1-dev:** use :latest until build runs, doc ImagePullBackOff limitation ([1831b46](https://github.com/brettswift/k8s_nas/commit/1831b4624f9916609ea90f626cb7fe2efe37c410))

## [1.0.1](https://github.com/brettswift/k8s_nas/compare/v1.0.0...v1.0.1) (2026-03-08)


### Bug Fixes

* **f1:** use A record (direct IP) instead of CNAME for f1 subdomains ([40aaf18](https://github.com/brettswift/k8s_nas/commit/40aaf1818407fc7893b3cd074455ba7cb5eb8695))

# 1.0.0 (2026-03-08)


### Bug Fixes

* add all required Homepage config files ([5c68f01](https://github.com/brettswift/k8s_nas/commit/5c68f01e79b30e84490fb4dc10be76a026323646))
* add ApplicationSet to nas project whitelist ([af528bb](https://github.com/brettswift/k8s_nas/commit/af528bb6448bb639c7f8e13c60d5c3d8eb0846f6))
* add bookmarks.yaml to Homepage ConfigMap ([503103d](https://github.com/brettswift/k8s_nas/commit/503103d2d16502f1050c3db355876f04059ca1ea))
* add Certificate health override to unblock infrastructure sync ([77ba821](https://github.com/brettswift/k8s_nas/commit/77ba821b6aa10904766ea4d37ccba074c75d6def)), closes [#4](https://github.com/brettswift/k8s_nas/issues/4)
* add Certificate health override to unblock infrastructure sync ([1790c4e](https://github.com/brettswift/k8s_nas/commit/1790c4e3ff264242886c138e75edb36dc6124203)), closes [#4](https://github.com/brettswift/k8s_nas/issues/4)
* add custom.js to Homepage ConfigMap ([071d433](https://github.com/brettswift/k8s_nas/commit/071d4335e295453ad94de107f878ab2fda3960a4))
* add docker.yaml to Homepage ConfigMap ([c242a99](https://github.com/brettswift/k8s_nas/commit/c242a99b12f35b46b9cfe9c6794c6cc3c4f66ce6))
* add homepage namespace to apps project destinations ([a91f2d9](https://github.com/brettswift/k8s_nas/commit/a91f2d99adb41c948dcfc5b4a4899d0ea087af23))
* add HOMEPAGE_ALLOWED_HOSTS environment variable ([1c64819](https://github.com/brettswift/k8s_nas/commit/1c648193c6cc86ce844bfe82cad85f56709931a1))
* add kube-system namespace to infrastructure project ([c2c85a2](https://github.com/brettswift/k8s_nas/commit/c2c85a2079f835ae83bafa6e754aa26c26cc3e2e))
* add kubernetes.yaml config for Homepage ([8cb40df](https://github.com/brettswift/k8s_nas/commit/8cb40dff1056908bb1421803eda485a6c62d31c8))
* add logs volume mount for Homepage ([6dd2275](https://github.com/brettswift/k8s_nas/commit/6dd2275e62a0a61c179a8280e2f321fdb5bded91))
* add missing f1-predictor ingress.yaml to repo ([22799ae](https://github.com/brettswift/k8s_nas/commit/22799ae3389817f2fc150600db5e09ced307fc7a))
* add namespace creation permission to apps project (before istio) ([7ae9150](https://github.com/brettswift/k8s_nas/commit/7ae91505b776f536eeebb4036a03b8ab74a7452c))
* Add priority annotation to qBittorrent ingress to override homepage ([5296694](https://github.com/brettswift/k8s_nas/commit/5296694075cdc8a258220e916dff4788124f7f4d))
* add RBAC permissions for Homepage widgets ([911efae](https://github.com/brettswift/k8s_nas/commit/911efaec5202b455ddddc90157699d5fcffe34eb))
* Add sub_filter to rewrite HTML asset paths in qBittorrent responses ([0323f71](https://github.com/brettswift/k8s_nas/commit/0323f717a36239a9a58a5533baef6fb8346c8fc3))
* add URI rewrite to VirtualService ([e75c997](https://github.com/brettswift/k8s_nas/commit/e75c997ebfdc8f2d7c30d183980c9a7fd06bcc1a))
* add widgets.yaml to Homepage ConfigMap ([fe6eede](https://github.com/brettswift/k8s_nas/commit/fe6eedeac7a9d9f402f909d17eece5d0adfb350c))
* Add wireguard-configmap to kustomization resources ([e9b4243](https://github.com/brettswift/k8s_nas/commit/e9b424385f41571dd5c6aa078cd5d3e98b888704))
* **argocd:** update infrastructure ApplicationSets to use correct branches and namespaces ([ba79923](https://github.com/brettswift/k8s_nas/commit/ba79923ac6e176727a74487cec69749deddf1647))
* **bazarr:** ensure single YAML document in config.yaml ([1f21e00](https://github.com/brettswift/k8s_nas/commit/1f21e00a8bfd576013a28e7275669a7d6a7576b1))
* **bazarr:** fix YAML config parsing by properly handling base_url in existing config file ([3f7fab0](https://github.com/brettswift/k8s_nas/commit/3f7fab06405fca8b6a14b4809ea8c03ece3c0605))
* **bazarr:** improve YAML cleanup to remove all document separators ([2952bc6](https://github.com/brettswift/k8s_nas/commit/2952bc6ffd1269ec11500257d38ce7808bfe9ee3))
* bind Blocky DNS to 10.1.0.20:53 to avoid systemd-resolved conflict ([e6d2550](https://github.com/brettswift/k8s_nas/commit/e6d2550bb894378d5fabc62fd71d7d828fdb33f4))
* bind Blocky DNS to 10.1.0.20:53 to avoid systemd-resolved conflict ([ad4aa4a](https://github.com/brettswift/k8s_nas/commit/ad4aa4adc87edaa55fb64da58668af2c2c7421a7))
* **BUD-29:** Fix namespace creation for dev/prod overlays ([0318d23](https://github.com/brettswift/k8s_nas/commit/0318d232f18a09ac14a6a9aafa2130f147681a05))
* **BUD-29:** Remove deprecated patchesStrategicMerge from kustomize ([ceefc64](https://github.com/brettswift/k8s_nas/commit/ceefc641263351ef90b69394d378f1d5de3f4194))
* **BUD-29:** Use external IP for f1.brettswift.com DNS ([db7d6a0](https://github.com/brettswift/k8s_nas/commit/db7d6a07fc102271b4b88ef6b0a8b2edfe247703))
* **BUD-29:** Use simple 'prod' namespace for f1-predictor ([623aa9e](https://github.com/brettswift/k8s_nas/commit/623aa9e04fb7bc25768ad67e504c1ebb3ffc4bcc))
* cert-sync from kube-system + doc cert renewal and TLS sync ([13ec32a](https://github.com/brettswift/k8s_nas/commit/13ec32a1296a0d3f27e60806166e1d50fa977d89))
* **cert:** switch to DNS-01 challenge for private network ([89323c9](https://github.com/brettswift/k8s_nas/commit/89323c960cca1070ef25e8824ce83f1306fd163b))
* clean root-app.yaml and point to applications directory ([ecf2d1d](https://github.com/brettswift/k8s_nas/commit/ecf2d1d3749a6aa1f834a3a58034b8f404b7cf37))
* configure Bazarr base path and fix ingress routing to resolve white page issue ([f8203df](https://github.com/brettswift/k8s_nas/commit/f8203df7282a5dee969b42acba9f233b5da701d4))
* consolidate Blocky under infrastructure app to resolve SharedResourceWarning ([4814be7](https://github.com/brettswift/k8s_nas/commit/4814be715733b08ebaedd47ed47af74de5c5069c))
* consolidate Blocky under infrastructure app to resolve SharedResourceWarning ([559d1e3](https://github.com/brettswift/k8s_nas/commit/559d1e35f746325056231196af25a012fdd7a3aa))
* consolidate Jekyll GitHub Pages workflows ([b04b8e5](https://github.com/brettswift/k8s_nas/commit/b04b8e5ad28ce7166f74ecf168800c3709c0e8f2))
* correct Istio Gateway and VirtualService configuration ([0524457](https://github.com/brettswift/k8s_nas/commit/05244574f2a07a3624bd43d3c8ec6a2eaffbf554))
* correct repo URLs and paths for applications ([d024a11](https://github.com/brettswift/k8s_nas/commit/d024a1123ddc23fdffcadfba4a47004733f9e2d8))
* correct VirtualService port to match service port ([d6512ef](https://github.com/brettswift/k8s_nas/commit/d6512ef251cf7683b22ead42189971c380b8f848))
* Correct YAML syntax in qbittorrent configmap heredoc ([be34fb0](https://github.com/brettswift/k8s_nas/commit/be34fb087eed448e3baa6fbcd901fe8d9174eb45))
* demo app environment variable display ([b8c3863](https://github.com/brettswift/k8s_nas/commit/b8c38632a9765d3460c44cf3fe016fb116d97ebf))
* deploy MCP server in permitted homeautomation namespace ([5579b19](https://github.com/brettswift/k8s_nas/commit/5579b192831dfa6758c4a57fa40bb34223676e23))
* Enable NVIDIA GPU hardware transcoding in Jellyfin ([a8b2261](https://github.com/brettswift/k8s_nas/commit/a8b2261cbf157c8dbd51708e7f4abba7f16e8da2))
* Enable qBittorrent WebUI RootFolder init script for ingress path ([dee799e](https://github.com/brettswift/k8s_nas/commit/dee799e5df90e92054df2615daf2e8e8543c8a90))
* f1 build - trigger on live/f1-dev only when image inputs change (Dockerfile, requirements, src) ([066e4a1](https://github.com/brettswift/k8s_nas/commit/066e4a1ea96de20798ddad8ca6a5d67d440039e0))
* **f1-predictor:** correct dev/prod split, ArgoCD paths, and DNS for home lab ([f7f628f](https://github.com/brettswift/k8s_nas/commit/f7f628f1d63538500e913f8c9a8b709b0fb4ad7c))
* **f1:** Correct 2026 race dates to match official F1 calendar ([4d2ed01](https://github.com/brettswift/k8s_nas/commit/4d2ed01540937d967005bb71123cb6ed883fce11))
* **f1:** Correct namespace name to match kustomization ([08555ec](https://github.com/brettswift/k8s_nas/commit/08555ecafe18b596d7fb38fff6006c2ae15740e1))
* **f1:** Remove hardcoded namespace from ingress manifests ([29834dc](https://github.com/brettswift/k8s_nas/commit/29834dce0478c35672ddde910141d286053c9191))
* **f1:** Split ingress to fix POST method not allowed ([b8a73a2](https://github.com/brettswift/k8s_nas/commit/b8a73a2dc110864f5878a797505d098ef53cb7fe))
* **f1:** Update driver seed to 2026 grid ([4f41a29](https://github.com/brettswift/k8s_nas/commit/4f41a296036fba7f73099dd35182feaeab48b7ba))
* **f1:** Update hardcoded 2025 text to 2026 ([25d840d](https://github.com/brettswift/k8s_nas/commit/25d840d73f7e01cf1dc8c671eaefc31eb9898385))
* Force SABnzbd VPN to use Vancouver server (yvr-c14) for better speeds ([b74184e](https://github.com/brettswift/k8s_nas/commit/b74184e86d97666fa7b241e1fd37b2af21f48112))
* GHCR script - timeout, progress, error handling for kubectl ([084607f](https://github.com/brettswift/k8s_nas/commit/084607fecca063706396ab4cc1956b8b6c6e71fa))
* hide front matter YAML keywords from rendered pages ([6030205](https://github.com/brettswift/k8s_nas/commit/6030205f0a3415d9c9172a3ce0d2bc3a0cf230f2))
* **homepage:** remove broken annotation patch, rely on ConfigMap hash ([ae0bda4](https://github.com/brettswift/k8s_nas/commit/ae0bda4b4b975c47733334b86854edc971e8ff18))
* **homepage:** update Jellyseerr link to use subdomain ([b1755e8](https://github.com/brettswift/k8s_nas/commit/b1755e85b4d9f989333de3b82e7fb54e0e5ef9bf))
* **homepage:** use patches to inject ConfigMap hash annotation ([6524e0b](https://github.com/brettswift/k8s_nas/commit/6524e0baaf4b2593a199332c42bfac0ee3a609e1))
* increase Jellyfin ingress file upload size limit to 50MB for branding images ([a78e142](https://github.com/brettswift/k8s_nas/commit/a78e14229474a25813032a460f09c25003e67dfa))
* Increase SABnzbd container resources for 100 connection downloads ([d28fd73](https://github.com/brettswift/k8s_nas/commit/d28fd73be1cf9215ab2e6ec3a9f95d1f42de2398))
* **infrastructure:** add Certificate and DaemonSet to infrastructure project permissions ([2218bc6](https://github.com/brettswift/k8s_nas/commit/2218bc6f06dd29a858870086576567b9e032fa61))
* **infrastructure:** fix nvidia-device-plugin label mismatch ([c825716](https://github.com/brettswift/k8s_nas/commit/c8257169a6bd998a68c96b15be8ed97b06c2829b))
* **infrastructure:** remove monitoring from infrastructure deployment ([c930c66](https://github.com/brettswift/k8s_nas/commit/c930c668696dca6a7af45ab280e9130caef06de5))
* **infrastructure:** remove non-existent nginx-ingress reference from kustomization ([440c1cc](https://github.com/brettswift/k8s_nas/commit/440c1cc912d467af700ce7e0a8004f6c9f782af1))
* **jellyfin:** change service type to ClusterIP and fix PVC storage class ([ab413f1](https://github.com/brettswift/k8s_nas/commit/ab413f12fc95dde89954e0a5ce815b5fd8e26f8c))
* **jellyseerr:** add proxy_redirect to fix /setup redirect including base path ([3c13a29](https://github.com/brettswift/k8s_nas/commit/3c13a29daa5cf9edc6ba71a789be0b420c0447d7))
* **jellyseerr:** disable default proxy_redirect before setting custom ones ([0f402cd](https://github.com/brettswift/k8s_nas/commit/0f402cdf7582a19377a2cc7da69f448ca8e75d47))
* **jellyseerr:** pass through full path to match BASE_URL configuration (remove rewrite-target) ([28dfbff](https://github.com/brettswift/k8s_nas/commit/28dfbffcb4a7d2cbaeba7fbf75b7ff0834a1c204))
* **jellyseerr:** restore working ingress configuration with rewrite-target and Next.js path rewrites ([73293ea](https://github.com/brettswift/k8s_nas/commit/73293ea9362370be742ce4aca3a1bf27c688b5eb))
* **jellyseerr:** strip path prefix and rewrite Location headers ([2e6f5e2](https://github.com/brettswift/k8s_nas/commit/2e6f5e21cb7d08d5c4902b6aa40f166cf0f6edda))
* **jellyseerr:** use server-snippet for proxy_redirect to fix /setup redirect ([6ebb04b](https://github.com/brettswift/k8s_nas/commit/6ebb04bdc46c8bc29660a7eb4323f1d7b9176bd1))
* Optimize SABnzbd VPN configuration ([083684b](https://github.com/brettswift/k8s_nas/commit/083684bdea37b332461babc8ed19078fc2ed6e55))
* Reduce sabnzbd revisionHistoryLimit to 3 ([4f3e711](https://github.com/brettswift/k8s_nas/commit/4f3e7111c4d7b26ee49bcdc08eadb602c5e6e612))
* Remove configuration-snippet to allow location block creation ([49f616c](https://github.com/brettswift/k8s_nas/commit/49f616ce337aabb11799432e07eec7567f652549))
* remove existing index.html before copying ([7c33067](https://github.com/brettswift/k8s_nas/commit/7c33067b9d07144bdd9ed65e6eaae4d26997964c))
* remove missing ingress-redirect from f1-predictor kustomization ([696b5dc](https://github.com/brettswift/k8s_nas/commit/696b5dc9351337c637fdbe8d5f51fe967733ded8))
* Remove path rewrite, let qBittorrent handle /qbittorrent with RootFolder ([5f05dc9](https://github.com/brettswift/k8s_nas/commit/5f05dc98842a395c17299c507564f3573849f967))
* remove paths filter from f1 build - was blocking f1-dev builds ([12caf38](https://github.com/brettswift/k8s_nas/commit/12caf38abc7ce5117f3eb6542c07b04b5e710ade))
* resolve Homepage deployment issues ([d06c8c7](https://github.com/brettswift/k8s_nas/commit/d06c8c7eb346490ae573d870699074596b62489a))
* restore NGINX ingress for port 30080 compatibility ([7fa3240](https://github.com/brettswift/k8s_nas/commit/7fa324009b53dd53898ec6a241cb69f339af73ad))
* restore paths filter for f1 build - only build when apps/f1-predictor changes ([9e47703](https://github.com/brettswift/k8s_nas/commit/9e477034ff81c0342032e4ffd718189d1fdaebdf))
* Revert to OpenVPN - IPVanish doesn't support WireGuard in gluetun ([aa19ffb](https://github.com/brettswift/k8s_nas/commit/aa19ffb10aff2f6a2b1277774b72f55c46b64c42))
* run HA MCP server in SSE mode for Home Assistant integration ([4db6707](https://github.com/brettswift/k8s_nas/commit/4db67075602fa8090402ea2a8d9f98555716bc6c))
* run MCP server via FastMCP SSE config for HA compatibility ([b5ab0ad](https://github.com/brettswift/k8s_nas/commit/b5ab0ad04c7fdab523cafbacf06d40659919e539))
* **sabnzbd:** increase memory limit to 2Gi to prevent OOMKill during unpack ([c15c89b](https://github.com/brettswift/k8s_nas/commit/c15c89b4bd8ac674212cb1c1c4bd556b80e942bc))
* **sabnzbd:** use local health check for VPN container (wget 127.0.0.1:9999) ([dfba253](https://github.com/brettswift/k8s_nas/commit/dfba253065ca62adb0b1b6080d41903298e29b4d))
* **sabnzbd:** use TCP probe for health checks (url_base agnostic) ([cfaa14c](https://github.com/brettswift/k8s_nas/commit/cfaa14c0530045d6ee193be0faf0649625191643))
* sample-hello deployment permission issue ([2e6eac7](https://github.com/brettswift/k8s_nas/commit/2e6eac79e2e4ed424da990796f91916253e94454))
* Set qBittorrent WebUI RootFolder to /qbittorrent for proper ingress routing ([0d2c206](https://github.com/brettswift/k8s_nas/commit/0d2c2066a48497c2e6b54bcd56757ac541b46ee6))
* simplify ingress path for /demo ([4900aa0](https://github.com/brettswift/k8s_nas/commit/4900aa078251ff3d8146dac4ae6034bb03f215ee))
* Simplify qBittorrent ingress - remove redirect loop ([1ccd9b7](https://github.com/brettswift/k8s_nas/commit/1ccd9b7efd04335467b0d7fd275d75612fb3180c))
* split Blocky to own app, add cert health skip for renewal ([072b727](https://github.com/brettswift/k8s_nas/commit/072b727e93796f266c7cd3d1bddf5d17dcd066ee))
* split Blocky to own app, add cert health skip for renewal ([5872aa5](https://github.com/brettswift/k8s_nas/commit/5872aa5c079de55c60e19901abb5a4c459cbd5c0))
* split f1 build - dev workflow always triggers on f1-dev push ([acad4d3](https://github.com/brettswift/k8s_nas/commit/acad4d30efbe212a86928052623a656207ba6191))
* **story-1.6:** configure SABnzbd to use /data/usenet/complete instead of nested complete/complete ([953952e](https://github.com/brettswift/k8s_nas/commit/953952e1129677565aa1184e9e0ec3a9336a4dbe))
* **story-1.6:** update docs to reflect simplified SABnzbd paths and correct server IP ([cb09561](https://github.com/brettswift/k8s_nas/commit/cb09561fdf654acaacbbd1db70b89cb166f13d91))
* **story-1.6:** update SABnzbd path mappings to match actual config (/data/usenet/complete/complete) ([cf5ea43](https://github.com/brettswift/k8s_nas/commit/cf5ea4334a2c2539ee650bb631d2e0cf820c803d))
* Switch qBittorrent to NGINX ingress with sub_filter for HTML rewriting ([9f9360c](https://github.com/brettswift/k8s_nas/commit/9f9360c94c3e4054976bdb9e73a9a8ed726ba9f0))
* Switch qBittorrent to Traefik ingress with StripPrefix middleware ([082c2f9](https://github.com/brettswift/k8s_nas/commit/082c2f99525954e970bef22ea85ee18433e30fe8))
* Switch SABnzbd VPN to WireGuard and increase CPU limits to fix throttling ([729232a](https://github.com/brettswift/k8s_nas/commit/729232a3f5d4406e8f86ea84c86982059c96448a))
* update F1 race dates to 2026 ([d80dab1](https://github.com/brettswift/k8s_nas/commit/d80dab1df2aaa26261bc83f76f2dc122d67916f1))
* update Homepage configuration and add TODO.md ([7001438](https://github.com/brettswift/k8s_nas/commit/7001438d25172dbd618813f4150f17e56dc67aa0))
* update infrastructure-appset to use main branch ([6a16117](https://github.com/brettswift/k8s_nas/commit/6a16117e0eda382ab79567410717e67ab882df7e))
* update Sonarr SABnzbd path mapping to use /usenet/complete instead of /downloads/usenet/complete ([16bf608](https://github.com/brettswift/k8s_nas/commit/16bf60867803c9e32e3593aaf61fdd3ef3d72a5f))
* use /metrics for Blocky health probes, update to denylists config ([3627187](https://github.com/brettswift/k8s_nas/commit/36271871067131f58195bf35d697a2eb33112b9e))
* use /metrics for Blocky health probes, update to denylists config ([61314b1](https://github.com/brettswift/k8s_nas/commit/61314b1cc9b1bb6d230b18d5746891c6e4053ff3))
* use Blocky image v0.28.2 (v0.28 tag not found) ([a436acf](https://github.com/brettswift/k8s_nas/commit/a436acf13df256fed0a195a7d4a7866dcdbe2dad))
* use Blocky image v0.28.2 (v0.28 tag not found) ([e80dafb](https://github.com/brettswift/k8s_nas/commit/e80dafb2b2c3826095351fc53f266434981cb08b))
* use ConfigMap for sample-hello content instead of file writes ([0c99404](https://github.com/brettswift/k8s_nas/commit/0c99404a0091e5ab8e960a6922ddb4dba92f9d05))
* Use correct WireGuard environment variables for gluetun ([d48f6bc](https://github.com/brettswift/k8s_nas/commit/d48f6bc5a25980e14f4b26ebfab438ffff8f658a))
* use default project for root-application ([347ec0b](https://github.com/brettswift/k8s_nas/commit/347ec0b7e8831dcead321646c094a6c249a9ed2a))
* use FQDN for Istio Gateway hosts ([fa41eff](https://github.com/brettswift/k8s_nas/commit/fa41eff54a6cd1e83ade2265184dbd6c0c647c61))
* use GHCR image for Home Assistant MCP server ([c8843ac](https://github.com/brettswift/k8s_nas/commit/c8843ac07d2b2dd7560fa4227e45a60a08cae089))
* use HTTPS for ArgoCD repoURL in f1-predictor appset ([3337870](https://github.com/brettswift/k8s_nas/commit/3337870f5b0c6f6bf3b4f7004b7cb69766cf62da))
* Use IPVanish WireGuard instead of custom config ([e60e808](https://github.com/brettswift/k8s_nas/commit/e60e8089f7b615310f1bd08e1f69b6c5582bfafd))
* use RELEASE_TOKEN for semantic-release, add PR + manual triggers ([475ce89](https://github.com/brettswift/k8s_nas/commit/475ce895591a39468de6f07416afa5e4330bdde5))
* Use simple rewrite-target / for qBittorrent (RootFolder not supported) ([bf03c3b](https://github.com/brettswift/k8s_nas/commit/bf03c3b82e0e54d167095d2115510190f35826b6))
* use tcpSocket probes for Blocky (HTTP /metrics returns 404) ([03433b1](https://github.com/brettswift/k8s_nas/commit/03433b1bf6a2cd5ea6be2643fff578086692d2c3))
* use tcpSocket probes for Blocky (HTTP /metrics returns 404) ([503d83d](https://github.com/brettswift/k8s_nas/commit/503d83d33b53112d8e1ecd011848e326bcfa8906))
* use wildcard hosts for Istio Gateway ([1589678](https://github.com/brettswift/k8s_nas/commit/1589678a8a90242dff1073a398dfab6731c17a48))


### Features

* add Blocky DNS ad blocker to infrastructure ([24a4614](https://github.com/brettswift/k8s_nas/commit/24a46146f5500a73f0ac91c76d30c74a126618b1))
* add Blocky DNS ad blocker to infrastructure ([6b3e296](https://github.com/brettswift/k8s_nas/commit/6b3e29600c4f15f0c78a12d25296e7c9086a6c46))
* add bootstrap system with Istio support ([205e3f6](https://github.com/brettswift/k8s_nas/commit/205e3f6049efcfd6b7c8e30f30aafa3216acb4e3))
* add dark theme and improved styling to GitHub Pages ([e67312e](https://github.com/brettswift/k8s_nas/commit/e67312e31c6d3c842452bdc9ba90df29bb3e7e5f))
* add f1 DNS script and troubleshooting ([8cff3f2](https://github.com/brettswift/k8s_nas/commit/8cff3f220f215a5b92f2a5951ad1e35b138d5a09))
* add Homepage dashboard with demo app as first link ([1fdbc70](https://github.com/brettswift/k8s_nas/commit/1fdbc7092c891e91a0df3305ae365a4deca1609e))
* add Istio Gateway and VirtualService for sample app ([e3cd21e](https://github.com/brettswift/k8s_nas/commit/e3cd21e9f12098a5a3057393c698b3eab66bbe17))
* add Istio routing indicator to demo app ([3016498](https://github.com/brettswift/k8s_nas/commit/3016498dc999f4155164269f16c9f0c5368b4f4f))
* Add qBittorrent DOCKER_MODS and enhance configuration docs ([a613b4c](https://github.com/brettswift/k8s_nas/commit/a613b4cc6021839d4597a9976c939f48bb68ac6f))
* Add script to create Route53 CNAME for qbittorrent subdomain ([24fd594](https://github.com/brettswift/k8s_nas/commit/24fd594a22b005d42567871242bb98ecdb180f80))
* add script to update Jellyfin splash screen image ([8922fe4](https://github.com/brettswift/k8s_nas/commit/8922fe4690d42beee017b490bfe27397d470b2f9))
* Add VPN sidecar container to SABnzbd deployment ([8024192](https://github.com/brettswift/k8s_nas/commit/8024192539db8bcb0e20a28c3db4c89a787fb7a1))
* **BUD-27:** Implement F1 prediction app ([965ff3c](https://github.com/brettswift/k8s_nas/commit/965ff3cae747c4964122b094c60da437ee83d3be))
* **BUD-29:** Add dev/prod environments for f1-predictor ([6062f8b](https://github.com/brettswift/k8s_nas/commit/6062f8b25fee272c0131c901b207763acf6e5082))
* **BUD-29:** Load drivers from Jolpica F1 API with weekly refresh ([5202673](https://github.com/brettswift/k8s_nas/commit/5202673afffa7d7f3a133e94d99a3389e8a46977))
* **cert-manager:** add wildcard certificate setup for *.home.brettswift.com ([d7b76c8](https://github.com/brettswift/k8s_nas/commit/d7b76c8297742c5629703d46f0e8035191219339))
* **cert:** automate certificate secret sync to all namespaces ([2abc218](https://github.com/brettswift/k8s_nas/commit/2abc218bef0094084a36c919b521152595417a2c))
* **cert:** implement HTTP-01 Let's Encrypt auto-renewal ([0a744a6](https://github.com/brettswift/k8s_nas/commit/0a744a63994ff6196e6318dd8c8ca3a4b4851297))
* **ci:** Add semantic-release for automated versioning ([9c392b8](https://github.com/brettswift/k8s_nas/commit/9c392b8c4954b2f1084ba9d73fbb1c90fc19733f))
* configure Istio-only setup with port 80 and domain routing ([3acb1bb](https://github.com/brettswift/k8s_nas/commit/3acb1bbfe2003d3ee3e827a6c3cb86f1d8909594))
* create-ghcr-pull-secret.sh supports 'all' namespaces ([18178b5](https://github.com/brettswift/k8s_nas/commit/18178b5f09fe9c3261bf157e1719386c11d1f632))
* deploy Home Assistant MCP server on mcp subdomain ([609fa35](https://github.com/brettswift/k8s_nas/commit/609fa357bf36a04cdfa2e674d7f023fc2f72ea50))
* f1.home.brettswift.com subdomain, document KUBECONFIG ([665fd1b](https://github.com/brettswift/k8s_nas/commit/665fd1bb530f7ceef087cec66d9f3dc4b26e0849))
* **f1:** Add automated race results fetcher ([69264c4](https://github.com/brettswift/k8s_nas/commit/69264c42266bcf61c46ad2a5c6433137ed9c1397))
* **f1:** tag images with git SHA - deploy fails until build completes, then succeeds ([59317ae](https://github.com/brettswift/k8s_nas/commit/59317aec2c0c60d6390e0bc43c48871b9bb0f3b3))
* **homepage:** auto-restart pod on ConfigMap changes ([b061a89](https://github.com/brettswift/k8s_nas/commit/b061a894d1498336515c98830355317b43fac838))
* **homepage:** limit replica sets display to last 3 ([20aedc3](https://github.com/brettswift/k8s_nas/commit/20aedc36619d654ab83c30df4ee0ce1d110715c6))
* **homepage:** set revisionHistoryLimit to 3 ([181b55e](https://github.com/brettswift/k8s_nas/commit/181b55e0d5c59dc14627bff317ca19f76cc08a43))
* implement Istio-only ApplicationSets pattern ([8ac1e9f](https://github.com/brettswift/k8s_nas/commit/8ac1e9f30c5e96eb644502bca17491d471c4d2df))
* implement proper ArgoCD project structure ([1cfd851](https://github.com/brettswift/k8s_nas/commit/1cfd8517c932ca80f9f2c8b78176e80334f7419e))
* implement working ApplicationSets pattern ([c8a0f4e](https://github.com/brettswift/k8s_nas/commit/c8a0f4eaa74aa1ddd19c2fc5be3d5db45dd2c04e))
* **jellyseerr:** switch from subfolder to subdomain deployment ([ba1fe87](https://github.com/brettswift/k8s_nas/commit/ba1fe87e2134eac1e9e809391cf61804c7cedafb))
* make Istio configuration fully GitOps-driven ([f769e89](https://github.com/brettswift/k8s_nas/commit/f769e89ce9839954e431619013024f4b61c8ffe3))
* remove infrastructure ApplicationSet ([d78a47a](https://github.com/brettswift/k8s_nas/commit/d78a47a6c2a6494cec83d7cdbc852d769c23a590))
* **story-1.6:** add script to create media root folders ([ab97be5](https://github.com/brettswift/k8s_nas/commit/ab97be5c62f0affce3bb266ed5fed76595983670))
* **story-1.6:** add usenet volume mount and fix /data mount path for root folders ([0d81500](https://github.com/brettswift/k8s_nas/commit/0d815008f3ec981ed11bdd6f6457d65f588e02bd))
* **story-1.6:** add verification script and UI configuration guide ([196fb9d](https://github.com/brettswift/k8s_nas/commit/196fb9d9bc34d01b9a7e1790471c2955cd2305b4))
* **story-1.6:** update story with completion notes and file list ([f192aea](https://github.com/brettswift/k8s_nas/commit/f192aea77b174840982fa45ba3cf07091fd0a6a6))
* **story-1.7:** verify prerequisites and create configuration guide ([dbe0640](https://github.com/brettswift/k8s_nas/commit/dbe0640a6d40066872a4f2c2466060448c460ba0))
* Switch certificate to wildcard *.home.brettswift.com for all subdomains ([fd9fcef](https://github.com/brettswift/k8s_nas/commit/fd9fcefab179e3cdbd7590f554f53adebfd75181))
* Switch qBittorrent to subdomain qbittorrent.home.brettswift.com ([cc4515d](https://github.com/brettswift/k8s_nas/commit/cc4515d41c2aae23d67d21f4a12ffe8c83e65e84))
* Use WireGuard config file for SABnzbd VPN ([b69028d](https://github.com/brettswift/k8s_nas/commit/b69028df4c7373c9a81aacafd6cddc00ac1ca369))


### Reverts

* f1-predictor local image only, no GHCR push ([3008ad0](https://github.com/brettswift/k8s_nas/commit/3008ad0cde34ff2618a1366bdf8c1cdc8f5551aa))
* Reduce SABnzbd resources to normal levels ([2af7ee5](https://github.com/brettswift/k8s_nas/commit/2af7ee5e75801510d8169468a6731960dfb18c28))
* remove duplicate client_max_body_size from Jellyfin ingress (was working fine) ([e6a8475](https://github.com/brettswift/k8s_nas/commit/e6a847544c0476411fce1f8b18ce1b817b408386))

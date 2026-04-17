# Cluster pod inventory

Generated from `kubectl get pods -A -o json` (current cluster context).

Re-run after changes:

```bash
kubectl get pods -A -o json | python3 k8s_nas/scripts/generate_pod_inventory_md.py
```

## Summary: all pods by phase

| Phase | Count |
|-------|------:|
| Running | 110 |
| Succeeded | 39 |
| Pending | 31 |
| Failed | 6 |
| **Total** | **186** |

## Summary: pod count by namespace

| Namespace | Pods |
|-----------|-----:|
| `qbittorrent` | 76 |
| `argocd` | 33 |
| `f1-predictor-dev` | 28 |
| `monitoring` | 12 |
| `media` | 9 |
| `cert-manager` | 7 |
| `kube-system` | 6 |
| `f1-predictor` | 5 |
| `homeautomation` | 3 |
| `homepage` | 2 |
| `openclaw` | 2 |
| `external-dns` | 1 |
| `ingress-nginx` | 1 |
| `travel-planner` | 1 |
| **Total** | **186** |

## `qbittorrent` (76 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `qbittorrent-f1-scraper-29590080-m7wjc` | Succeeded | - | - | `Job/qbittorrent-f1-scraper-29590080` |
| `qbittorrent-f1-scraper-29590140-kvjx8` | Succeeded | - | - | `Job/qbittorrent-f1-scraper-29590140` |
| `qbittorrent-f1-scraper-29590200-8vdwk` | Succeeded | - | - | `Job/qbittorrent-f1-scraper-29590200` |
| `qbittorrent-f1-scraper-29590260-t86jg` | Running | - | - | `Job/qbittorrent-f1-scraper-29590260` |
| `qbittorrent-f1-scraper-29590320-26h26` | Running | - | - | `Job/qbittorrent-f1-scraper-29590320` |
| `qbittorrent-f1-scraper-29590380-9r4vv` | Running | - | - | `Job/qbittorrent-f1-scraper-29590380` |
| `qbittorrent-f1-scraper-29590440-qf8mm` | Running | - | - | `Job/qbittorrent-f1-scraper-29590440` |
| `qbittorrent-f1-scraper-29590500-q5j6b` | Running | - | - | `Job/qbittorrent-f1-scraper-29590500` |
| `qbittorrent-f1-scraper-29590560-cgf7g` | Running | - | - | `Job/qbittorrent-f1-scraper-29590560` |
| `qbittorrent-f1-scraper-29590620-qdc7t` | Running | - | - | `Job/qbittorrent-f1-scraper-29590620` |
| `qbittorrent-f1-scraper-29595660-6gb6j` | Running | - | - | `Job/qbittorrent-f1-scraper-29595660` |
| `qbittorrent-f1-scraper-29595720-6kq4d` | Running | - | - | `Job/qbittorrent-f1-scraper-29595720` |
| `qbittorrent-f1-scraper-29595780-vzsj9` | Running | - | - | `Job/qbittorrent-f1-scraper-29595780` |
| `qbittorrent-f1-scraper-29595840-czhbj` | Running | - | - | `Job/qbittorrent-f1-scraper-29595840` |
| `qbittorrent-f1-scraper-29595900-2s2z2` | Running | - | - | `Job/qbittorrent-f1-scraper-29595900` |
| `qbittorrent-f1-scraper-29595960-zpdqr` | Running | - | - | `Job/qbittorrent-f1-scraper-29595960` |
| `qbittorrent-f1-scraper-29596020-8qzvz` | Running | - | - | `Job/qbittorrent-f1-scraper-29596020` |
| `qbittorrent-f1-scraper-29596080-ltfkx` | Running | - | - | `Job/qbittorrent-f1-scraper-29596080` |
| `qbittorrent-f1-scraper-29596140-2s45g` | Running | - | - | `Job/qbittorrent-f1-scraper-29596140` |
| `qbittorrent-f1-scraper-29596200-ztspz` | Running | - | - | `Job/qbittorrent-f1-scraper-29596200` |
| `qbittorrent-f1-scraper-29596260-z5pk9` | Running | - | - | `Job/qbittorrent-f1-scraper-29596260` |
| `qbittorrent-f1-scraper-29596320-x9z57` | Running | - | - | `Job/qbittorrent-f1-scraper-29596320` |
| `qbittorrent-f1-scraper-29596380-fv586` | Running | - | - | `Job/qbittorrent-f1-scraper-29596380` |
| `qbittorrent-f1-scraper-29597100-zk4dd` | Running | - | - | `Job/qbittorrent-f1-scraper-29597100` |
| `qbittorrent-f1-scraper-29597160-wgjrt` | Running | - | - | `Job/qbittorrent-f1-scraper-29597160` |
| `qbittorrent-f1-scraper-29597220-j5jgd` | Running | - | - | `Job/qbittorrent-f1-scraper-29597220` |
| `qbittorrent-f1-scraper-29597280-gvq9z` | Running | - | - | `Job/qbittorrent-f1-scraper-29597280` |
| `qbittorrent-f1-scraper-29597340-5xx9k` | Running | - | - | `Job/qbittorrent-f1-scraper-29597340` |
| `qbittorrent-f1-scraper-29597400-trcqx` | Running | - | - | `Job/qbittorrent-f1-scraper-29597400` |
| `qbittorrent-f1-scraper-29597460-6fkpm` | Running | - | - | `Job/qbittorrent-f1-scraper-29597460` |
| `qbittorrent-f1-scraper-29597520-sh24l` | Running | - | - | `Job/qbittorrent-f1-scraper-29597520` |
| `qbittorrent-f1-scraper-29597580-72mwf` | Running | - | - | `Job/qbittorrent-f1-scraper-29597580` |
| `qbittorrent-f1-scraper-29597640-dg4rk` | Running | - | - | `Job/qbittorrent-f1-scraper-29597640` |
| `qbittorrent-f1-scraper-29597700-rlr9g` | Running | - | - | `Job/qbittorrent-f1-scraper-29597700` |
| `qbittorrent-f1-scraper-29597760-4xvxm` | Running | - | - | `Job/qbittorrent-f1-scraper-29597760` |
| `qbittorrent-f1-scraper-29597820-jwcgc` | Running | - | - | `Job/qbittorrent-f1-scraper-29597820` |
| `qbittorrent-f1-scraper-29598540-bdrpz` | Running | - | - | `Job/qbittorrent-f1-scraper-29598540` |
| `qbittorrent-f1-scraper-29598600-4ftzm` | Running | - | - | `Job/qbittorrent-f1-scraper-29598600` |
| `qbittorrent-f1-scraper-29598660-rcwhz` | Running | - | - | `Job/qbittorrent-f1-scraper-29598660` |
| `qbittorrent-f1-scraper-29598720-22cqm` | Running | - | - | `Job/qbittorrent-f1-scraper-29598720` |
| `qbittorrent-f1-scraper-29598780-htj4x` | Running | - | - | `Job/qbittorrent-f1-scraper-29598780` |
| `qbittorrent-f1-scraper-29598840-b9vn9` | Running | - | - | `Job/qbittorrent-f1-scraper-29598840` |
| `qbittorrent-f1-scraper-29598900-fwmww` | Running | - | - | `Job/qbittorrent-f1-scraper-29598900` |
| `qbittorrent-f1-scraper-29598960-rf95h` | Running | - | - | `Job/qbittorrent-f1-scraper-29598960` |
| `qbittorrent-f1-scraper-29599020-zlrxj` | Running | - | - | `Job/qbittorrent-f1-scraper-29599020` |
| `qbittorrent-f1-scraper-29599080-f7n92` | Running | - | - | `Job/qbittorrent-f1-scraper-29599080` |
| `qbittorrent-f1-scraper-29599140-ccmlm` | Running | - | - | `Job/qbittorrent-f1-scraper-29599140` |
| `qbittorrent-f1-scraper-29599200-nzjwf` | Running | - | - | `Job/qbittorrent-f1-scraper-29599200` |
| `qbittorrent-f1-scraper-29599260-4g6gl` | Running | - | - | `Job/qbittorrent-f1-scraper-29599260` |
| `qbittorrent-f1-scraper-29599980-9bdj2` | Running | - | - | `Job/qbittorrent-f1-scraper-29599980` |
| `qbittorrent-f1-scraper-29600040-dk5n9` | Running | - | - | `Job/qbittorrent-f1-scraper-29600040` |
| `qbittorrent-f1-scraper-29600100-rw6ht` | Running | - | - | `Job/qbittorrent-f1-scraper-29600100` |
| `qbittorrent-f1-scraper-29600160-cvjx7` | Running | - | - | `Job/qbittorrent-f1-scraper-29600160` |
| `qbittorrent-f1-scraper-29600220-vh5h8` | Running | - | - | `Job/qbittorrent-f1-scraper-29600220` |
| `qbittorrent-f1-scraper-29600280-sqkh8` | Running | - | - | `Job/qbittorrent-f1-scraper-29600280` |
| `qbittorrent-f1-scraper-29600340-vjmfs` | Running | - | - | `Job/qbittorrent-f1-scraper-29600340` |
| `qbittorrent-f1-scraper-29600400-bpvjc` | Running | - | - | `Job/qbittorrent-f1-scraper-29600400` |
| `qbittorrent-f1-scraper-29600460-jt27z` | Running | - | - | `Job/qbittorrent-f1-scraper-29600460` |
| `qbittorrent-f1-scraper-29600520-pq8kt` | Running | - | - | `Job/qbittorrent-f1-scraper-29600520` |
| `qbittorrent-f1-scraper-29600580-c785w` | Running | - | - | `Job/qbittorrent-f1-scraper-29600580` |
| `qbittorrent-f1-scraper-29600640-qg2zf` | Running | - | - | `Job/qbittorrent-f1-scraper-29600640` |
| `qbittorrent-f1-scraper-29600700-5zf7n` | Running | - | - | `Job/qbittorrent-f1-scraper-29600700` |
| `qbittorrent-f1-scraper-29605740-ftslb` | Running | - | - | `Job/qbittorrent-f1-scraper-29605740` |
| `qbittorrent-f1-scraper-29605800-7m5sr` | Running | - | - | `Job/qbittorrent-f1-scraper-29605800` |
| `qbittorrent-f1-scraper-29605860-kcbts` | Running | - | - | `Job/qbittorrent-f1-scraper-29605860` |
| `qbittorrent-f1-scraper-29605920-x4klr` | Running | - | - | `Job/qbittorrent-f1-scraper-29605920` |
| `qbittorrent-f1-scraper-29605980-sld8c` | Running | - | - | `Job/qbittorrent-f1-scraper-29605980` |
| `qbittorrent-f1-scraper-29606040-7dfs2` | Running | - | - | `Job/qbittorrent-f1-scraper-29606040` |
| `qbittorrent-f1-scraper-29606100-tdllh` | Running | - | - | `Job/qbittorrent-f1-scraper-29606100` |
| `qbittorrent-f1-scraper-29606160-dvch4` | Running | - | - | `Job/qbittorrent-f1-scraper-29606160` |
| `qbittorrent-f1-scraper-29606220-2ppbh` | Pending | - | - | `Job/qbittorrent-f1-scraper-29606220` |
| `qbittorrent-f1-scraper-29606280-zmzxj` | Pending | - | - | `Job/qbittorrent-f1-scraper-29606280` |
| `qbittorrent-f1-scraper-29606340-p7tft` | Running | - | - | `Job/qbittorrent-f1-scraper-29606340` |
| `qbittorrent-f1-scraper-29606400-x5m6w` | Pending | - | - | `Job/qbittorrent-f1-scraper-29606400` |
| `qbittorrent-f1-scraper-29606460-bnhqz` | Pending | - | - | `Job/qbittorrent-f1-scraper-29606460` |
| `qbittorrent-5c769bf858-g864c` | Running | qbittorrent | - | `ReplicaSet/qbittorrent-5c769bf858` |

## `argocd` (33 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `sync-cert-secret-29606145-tvsn9` | Succeeded | - | - | `Job/sync-cert-secret-29606145` |
| `sync-cert-secret-29606160-5ctl4` | Pending | - | - | `Job/sync-cert-secret-29606160` |
| `sync-cert-secret-29606175-28s9j` | Succeeded | - | - | `Job/sync-cert-secret-29606175` |
| `sync-cert-secret-29606190-bchrn` | Pending | - | - | `Job/sync-cert-secret-29606190` |
| `sync-cert-secret-29606205-2kr8c` | Pending | - | - | `Job/sync-cert-secret-29606205` |
| `sync-cert-secret-29606220-lfkls` | Pending | - | - | `Job/sync-cert-secret-29606220` |
| `sync-cert-secret-29606235-87js5` | Pending | - | - | `Job/sync-cert-secret-29606235` |
| `sync-cert-secret-29606250-qjhhh` | Pending | - | - | `Job/sync-cert-secret-29606250` |
| `sync-cert-secret-29606265-25zdj` | Pending | - | - | `Job/sync-cert-secret-29606265` |
| `sync-cert-secret-29606280-c6w8j` | Pending | - | - | `Job/sync-cert-secret-29606280` |
| `sync-cert-secret-29606295-pdssl` | Pending | - | - | `Job/sync-cert-secret-29606295` |
| `sync-cert-secret-29606310-h68w2` | Pending | - | - | `Job/sync-cert-secret-29606310` |
| `sync-cert-secret-29606325-rcmd4` | Pending | - | - | `Job/sync-cert-secret-29606325` |
| `sync-cert-secret-29606340-r8j6r` | Succeeded | - | - | `Job/sync-cert-secret-29606340` |
| `sync-cert-secret-29606355-76v4b` | Pending | - | - | `Job/sync-cert-secret-29606355` |
| `sync-cert-secret-29606370-rdncg` | Pending | - | - | `Job/sync-cert-secret-29606370` |
| `sync-cert-secret-29606385-tlxxk` | Pending | - | - | `Job/sync-cert-secret-29606385` |
| `sync-cert-secret-29606400-ctm24` | Pending | - | - | `Job/sync-cert-secret-29606400` |
| `sync-cert-secret-29606415-p2j78` | Pending | - | - | `Job/sync-cert-secret-29606415` |
| `sync-cert-secret-29606430-z2548` | Pending | - | - | `Job/sync-cert-secret-29606430` |
| `sync-cert-secret-29606445-mwk62` | Pending | - | - | `Job/sync-cert-secret-29606445` |
| `sync-cert-secret-29606460-tpbdv` | Pending | - | - | `Job/sync-cert-secret-29606460` |
| `sync-cert-secret-29606475-4q2gz` | Pending | - | - | `Job/sync-cert-secret-29606475` |
| `sync-cert-secret-29606490-rdq6q` | Pending | - | - | `Job/sync-cert-secret-29606490` |
| `sync-cert-secret-29606505-x59m7` | Pending | - | - | `Job/sync-cert-secret-29606505` |
| `sync-cert-secret-29606520-8rnqd` | Pending | - | - | `Job/sync-cert-secret-29606520` |
| `argocd-application-controller-0` | Running | argocd-application-controller | - | `StatefulSet/argocd-application-controller` |
| `argocd-applicationset-controller-fc5545556-64kkp` | Running | argocd-applicationset-controller | - | `ReplicaSet/argocd-applicationset-controller-fc5545556` |
| `argocd-dex-server-f59c65cff-7svcw` | Running | argocd-dex-server | - | `ReplicaSet/argocd-dex-server-f59c65cff` |
| `argocd-notifications-controller-59f6949d7-n6qws` | Running | argocd-notifications-controller | - | `ReplicaSet/argocd-notifications-controller-59f6949d7` |
| `argocd-redis-75c946f559-7qhk6` | Running | argocd-redis | - | `ReplicaSet/argocd-redis-75c946f559` |
| `argocd-repo-server-6959c47c44-8sbgn` | Running | argocd-repo-server | - | `ReplicaSet/argocd-repo-server-6959c47c44` |
| `argocd-server-5dd776d679-kc4s4` | Running | argocd-server | - | `ReplicaSet/argocd-server-5dd776d679` |

## `f1-predictor-dev` (28 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `check-drivers-now` | Succeeded | - | - | `-` |
| `check-f1-races-now` | Failed | - | - | `-` |
| `check-f1-schema` | Succeeded | - | - | `-` |
| `check-f1-status` | Failed | - | - | `-` |
| `check-f1-status2` | Succeeded | - | - | `-` |
| `check-now` | Succeeded | - | - | `-` |
| `check-race-status` | Succeeded | - | - | `-` |
| `check-results` | Succeeded | - | - | `-` |
| `check-results-now` | Succeeded | - | - | `-` |
| `check-results2` | Succeeded | - | - | `-` |
| `check-schema` | Succeeded | - | - | `-` |
| `check-schema2` | Succeeded | - | - | `-` |
| `check-users` | Failed | - | - | `-` |
| `check-users2` | Succeeded | - | - | `-` |
| `check-users3` | Failed | - | - | `-` |
| `cleanup-users` | Succeeded | - | - | `-` |
| `clear-f1-races` | Succeeded | - | - | `-` |
| `clear-f1-races2` | Succeeded | - | - | `-` |
| `db-reset-temp` | Succeeded | - | - | `-` |
| `image-refresh-qxrqh` | Succeeded | - | - | `Job/image-refresh` |
| `reset-mock-db` | Succeeded | - | - | `-` |
| `seed-fixtures` | Failed | - | - | `-` |
| `seed-fixtures2` | Succeeded | - | - | `-` |
| `seed-mock-fixtures` | Failed | - | - | `-` |
| `set-future-races` | Succeeded | - | - | `-` |
| `setup-users` | Succeeded | - | - | `-` |
| `f1-mock-api-7ffcdc44cc-pl786` | Pending | f1-mock-api | - | `ReplicaSet/f1-mock-api-7ffcdc44cc` |
| `f1-predictor-759478fb57-vrpj2` | Running | f1-predictor | - | `ReplicaSet/f1-predictor-759478fb57` |

## `monitoring` (12 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `curl-pg` | Succeeded | - | - | `-` |
| `sabnzbd-vpn-check-29606160-tr25c` | Pending | - | - | `Job/sabnzbd-vpn-check-29606160` |
| `alloy-2nqs4` | Running | alloy | - | `DaemonSet/alloy` |
| `grafana-58f5c49986-kts6s` | Running | grafana | - | `ReplicaSet/grafana-58f5c49986` |
| `grafana-ntfy-proxy-68895cd5f6-tv7tf` | Running | grafana-ntfy-proxy | - | `ReplicaSet/grafana-ntfy-proxy-68895cd5f6` |
| `loki-847c4b4697-862p4` | Running | loki | - | `ReplicaSet/loki-847c4b4697` |
| `prometheus-5477465f75-zzh8p` | Running | prometheus | - | `ReplicaSet/prometheus-5477465f75` |
| `pushgateway-596c95cd67-p9c25` | Running | pushgateway | - | `ReplicaSet/pushgateway-596c95cd67` |
| `uptime-kuma-6d786485d8-hccrt` | Running | uptime-kuma | - | `ReplicaSet/uptime-kuma-6d786485d8` |
| `uptime-kuma-sync-29602560-szbw8` | Succeeded | uptime-kuma-sync | - | `Job/uptime-kuma-sync-29602560` |
| `uptime-kuma-sync-29604000-s8x54` | Succeeded | uptime-kuma-sync | - | `Job/uptime-kuma-sync-29604000` |
| `uptime-kuma-sync-29605440-v92tp` | Succeeded | uptime-kuma-sync | - | `Job/uptime-kuma-sync-29605440` |

## `media` (9 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `bazarr-67f4c4db54-n5lqb` | Running | bazarr | - | `ReplicaSet/bazarr-67f4c4db54` |
| `jellyfin-6db99b9747-7hndk` | Running | jellyfin | - | `ReplicaSet/jellyfin-6db99b9747` |
| `jellyseerr-576f96845d-sm8gk` | Running | jellyseerr | - | `ReplicaSet/jellyseerr-576f96845d` |
| `lidarr-7d8bbf4948-twl9f` | Running | lidarr | - | `ReplicaSet/lidarr-7d8bbf4948` |
| `prowlarr-6cd86bf57-4vt6z` | Running | prowlarr | - | `ReplicaSet/prowlarr-6cd86bf57` |
| `radarr-9689b67c9-cvqbs` | Running | radarr | - | `ReplicaSet/radarr-9689b67c9` |
| `sabnzbd-d8fc4fdd8-4p4rn` | Running | sabnzbd | - | `ReplicaSet/sabnzbd-d8fc4fdd8` |
| `sonarr-85c6f59ff7-bsv96` | Running | sonarr | - | `ReplicaSet/sonarr-85c6f59ff7` |
| `unpackerr-5dfb9dc99d-vl2nq` | Running | unpackerr | - | `ReplicaSet/unpackerr-5dfb9dc99d` |

## `cert-manager` (7 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `sync-route53-credentials-29605320-dhktv` | Succeeded | - | - | `Job/sync-route53-credentials-29605320` |
| `sync-route53-credentials-29605680-8gsms` | Succeeded | - | - | `Job/sync-route53-credentials-29605680` |
| `sync-route53-credentials-29606040-md9r4` | Succeeded | - | - | `Job/sync-route53-credentials-29606040` |
| `sync-route53-credentials-29606400-l5c4g` | Pending | - | - | `Job/sync-route53-credentials-29606400` |
| `cert-manager-cainjector-546bc658d4-csjwq` | Running | cainjector | cainjector | `ReplicaSet/cert-manager-cainjector-546bc658d4` |
| `cert-manager-8bd5cbd59-thvf5` | Running | cert-manager | controller | `ReplicaSet/cert-manager-8bd5cbd59` |
| `cert-manager-webhook-66d7f4599d-wm975` | Running | webhook | webhook | `ReplicaSet/cert-manager-webhook-66d7f4599d` |

## `kube-system` (6 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `helm-install-traefik-6xnwz` | Succeeded | - | - | `Job/helm-install-traefik` |
| `helm-install-traefik-crd-v4bgz` | Succeeded | - | - | `Job/helm-install-traefik-crd` |
| `coredns-6d668d687-2kswb` | Running | kube-dns | - | `ReplicaSet/coredns-6d668d687` |
| `local-path-provisioner-869c44bfbd-dm87k` | Running | local-path-provisioner | - | `ReplicaSet/local-path-provisioner-869c44bfbd` |
| `metrics-server-7bfffcd44-fqh4q` | Running | metrics-server | - | `ReplicaSet/metrics-server-7bfffcd44` |
| `traefik-865bd56545-72z7j` | Running | traefik | - | `ReplicaSet/traefik-865bd56545` |

## `f1-predictor` (5 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `f1-driver-refresh-29579520-swdtj` | Succeeded | - | - | `Job/f1-driver-refresh-29579520` |
| `f1-driver-refresh-29589600-kzn7k` | Succeeded | - | - | `Job/f1-driver-refresh-29589600` |
| `f1-driver-refresh-29599680-8cgzw` | Succeeded | - | - | `Job/f1-driver-refresh-29599680` |
| `image-refresh-zsvg9` | Succeeded | - | - | `Job/image-refresh` |
| `f1-predictor-dfb5c8944-9hhgg` | Running | f1-predictor | - | `ReplicaSet/f1-predictor-dfb5c8944` |

## `homeautomation` (3 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `homeassistant-588fb47c5-s62j2` | Running | homeassistant | - | `ReplicaSet/homeassistant-588fb47c5` |
| `matter-server-85cfc84655-bltqj` | Running | matter-server | - | `ReplicaSet/matter-server-85cfc84655` |
| `mcp-server-8645975699-s8lpv` | Running | mcp-server | - | `ReplicaSet/mcp-server-8645975699` |

## `homepage` (2 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `homepage-7b74977dd7-pkstt` | Running | homepage | - | `ReplicaSet/homepage-7b74977dd7` |
| `homepage-ff6dbd9b-gmc8m` | Pending | homepage | - | `ReplicaSet/homepage-ff6dbd9b` |

## `openclaw` (2 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `openclaw-gateway-6788857754-knvhw` | Running | openclaw-gateway | - | `ReplicaSet/openclaw-gateway-6788857754` |
| `searxng-7b6b75b764-glc4c` | Running | searxng | - | `ReplicaSet/searxng-7b6b75b764` |

## `external-dns` (1 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `external-dns-5c9c76788b-gzrtz` | Running | external-dns | - | `ReplicaSet/external-dns-5c9c76788b` |

## `ingress-nginx` (1 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `ingress-nginx-controller-6bb65b4777-z5qs4` | Running | ingress-nginx | controller | `ReplicaSet/ingress-nginx-controller-6bb65b4777` |

## `travel-planner` (1 pods)

| Pod | Phase | app / name label | component | controller owner |
|-----|-------|-------------------|-----------|------------------|
| `travel-planner-6b5dc7c8cc-ch5vw` | Running | travel-planner | - | `ReplicaSet/travel-planner-6b5dc7c8cc` |

# F1 Predictor

Image is built by GitHub Actions and pushed to `ghcr.io/brettswift/f1-predictor:latest`.

**First deploy:** Run the "Build f1-predictor image" workflow (Actions → Build f1-predictor image → Run) before the pod can pull the image.

**Private package:** If the GHCR package is private, add an imagePullSecret to the deployment. See [GitHub docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-to-the-container-registry).

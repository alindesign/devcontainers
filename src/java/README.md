# java

Java (Eclipse Temurin by default) via [mise](https://mise.jdx.dev). Auto-bootstraps mise if not present.

## Options

| Option | Type | Default | Notes |
| --- | --- | --- | --- |
| `version` | string | `temurin-21` | mise java spec (`temurin-21`, `corretto-17`, `openjdk-21`, or `21`). |
| `installMaven` | boolean | `false` | Also install Maven via mise. |
| `installGradle` | boolean | `false` | Also install Gradle via mise. |

## Use

```jsonc
{
  "features": {
    "ghcr.io/alindesign/features/java:1": {
      "version": "temurin-21",
      "installMaven": true
    }
  }
}
```

`JAVA_HOME` is set system-wide via `/etc/profile.d/java.sh` and re-exported in the remote user's rc files.

# Open WebUI Customization Catalog

Complete inventory of every customization surface, classified by method.

## Classification Legend

| Tag | Meaning |
|-----|---------|
| **RUNTIME-ENV** | Set via environment variable, no image change |
| **RUNTIME-DB** | Configured via Admin UI, persisted in database |
| **VOLUME-MOUNT** | Override by mounting a file/dir into the container |
| **SIDECAR** | Separate service connected to Open WebUI |
| **DERIVED-IMAGE** | Requires building `FROM ghcr.io/open-webui/open-webui` |
| **FORK** | Requires source code modification and full rebuild |

---

## 1. LLM Provider Connections

| Customization | Method | Details |
|---------------|--------|---------|
| Ollama endpoints | RUNTIME-ENV / RUNTIME-DB | `OLLAMA_BASE_URLS` (semicolon-separated), or Admin > Connections |
| OpenAI-compatible endpoints | RUNTIME-ENV / RUNTIME-DB | `OPENAI_API_BASE_URLS`, `OPENAI_API_KEYS` (semicolon-separated) |
| Per-connection config (headers, auth, model filter) | RUNTIME-ENV / RUNTIME-DB | `OPENAI_API_CONFIGS` / `OLLAMA_API_CONFIGS` JSON, or Admin UI |
| Azure AD auth for connections | RUNTIME-DB | Set `auth_type: "azure_ad"` in connection config |
| Gemini API | RUNTIME-ENV | `GEMINI_API_KEY`, `GEMINI_API_BASE_URL` |
| Enable/disable Ollama API | RUNTIME-ENV / RUNTIME-DB | `ENABLE_OLLAMA_API` |
| Enable/disable OpenAI API | RUNTIME-ENV / RUNTIME-DB | `ENABLE_OPENAI_API` |
| Direct user connections | RUNTIME-ENV / RUNTIME-DB | `ENABLE_DIRECT_CONNECTIONS` |
| Default/pinned models | RUNTIME-DB | Admin > Models: `DEFAULT_MODELS`, `DEFAULT_PINNED_MODELS` |
| Model ordering | RUNTIME-DB | `MODEL_ORDER_LIST` via Admin UI |
| Custom model aliases | RUNTIME-DB | Admin > Models: create workspace models with custom params/filters |
| Model access control bypass | RUNTIME-ENV | `BYPASS_MODEL_ACCESS_CONTROL` |
| Model list cache TTL | RUNTIME-ENV | `MODELS_CACHE_TTL` (seconds) |

---

## 2. Plugin System (Functions, Tools, Pipelines)

| Customization | Method | Details |
|---------------|--------|---------|
| Enable/disable plugins | RUNTIME-ENV | `ENABLE_PLUGINS` (default true) |
| Safe mode (deactivate all functions) | RUNTIME-ENV | `SAFE_MODE` |
| Pipe functions (custom model endpoints) | RUNTIME-DB | Admin > Functions: Python code stored in DB |
| Filter functions (chat inlet/outlet) | RUNTIME-DB | Admin > Functions: intercept/transform chat |
| Action functions (UI actions) | RUNTIME-DB | Admin > Functions: button actions in chat |
| Event functions (react to system events) | RUNTIME-DB | Admin > Functions: `type='event'` handlers |
| Tools (LLM-callable Python) | RUNTIME-DB | Workspace > Tools: Python `Tools` class in DB |
| Tool permissions | RUNTIME-DB | `ENABLE_TOOL_PERMISSIONS` |
| Pipelines (external filter service) | SIDECAR | `ghcr.io/open-webui/pipelines`, connected as OpenAI endpoint |
| MCP tool servers | RUNTIME-DB / RUNTIME-ENV | `TOOL_SERVER_CONNECTIONS` JSON, or Admin > Integrations |
| OpenAPI tool servers | RUNTIME-DB | Admin > Integrations |
| Terminal servers | RUNTIME-ENV / RUNTIME-DB | `TERMINAL_SERVER_CONNECTIONS` |
| Function/tool pip dependencies | RUNTIME-ENV | `ENABLE_PIP_INSTALL_FRONTMATTER_REQUIREMENTS`, `PIP_OPTIONS` |
| Valve encryption | RUNTIME-ENV | `ENABLE_VALVE_ENCRYPTION` |

---

## 3. Authentication & Authorization

| Customization | Method | Details |
|---------------|--------|---------|
| Enable/disable auth | RUNTIME-ENV | `WEBUI_AUTH` (default true) |
| Enable signup | RUNTIME-ENV / RUNTIME-DB | `ENABLE_SIGNUP` |
| Enable login form | RUNTIME-DB | `ENABLE_LOGIN_FORM` |
| OAuth2/OIDC (generic) | RUNTIME-ENV / RUNTIME-DB | `OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`, `OPENID_PROVIDER_URL`, etc. |
| Google OAuth | RUNTIME-ENV / RUNTIME-DB | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` |
| Microsoft OAuth | RUNTIME-ENV / RUNTIME-DB | `MICROSOFT_CLIENT_ID`, `MICROSOFT_CLIENT_SECRET`, `MICROSOFT_CLIENT_TENANT_ID` |
| GitHub OAuth | RUNTIME-ENV / RUNTIME-DB | `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET` |
| Feishu OAuth | RUNTIME-ENV / RUNTIME-DB | `FEISHU_CLIENT_ID`, `FEISHU_CLIENT_SECRET` |
| LDAP | RUNTIME-ENV / RUNTIME-DB | `ENABLE_LDAP`, `LDAP_SERVER_HOST`, etc. |
| Trusted headers (SSO proxy) | RUNTIME-ENV | `WEBUI_AUTH_TRUSTED_EMAIL_HEADER`, `WEBUI_AUTH_TRUSTED_NAME_HEADER` |
| API keys | RUNTIME-DB | `ENABLE_API_KEYS`, `ENABLE_API_KEYS_ENDPOINT_RESTRICTIONS` |
| Custom API key header | RUNTIME-ENV | `CUSTOM_API_KEY_HEADER` |
| JWT expiry | RUNTIME-DB | `JWT_EXPIRES_IN` |
| OAuth role/group mapping | RUNTIME-DB | `ENABLE_OAUTH_ROLE_MANAGEMENT`, `ENABLE_OAUTH_GROUP_MANAGEMENT` |
| OAuth token exchange | RUNTIME-ENV | `ENABLE_OAUTH_TOKEN_EXCHANGE` |
| Back-channel logout | RUNTIME-ENV | `ENABLE_OAUTH_BACKCHANNEL_LOGOUT` |
| SCIM provisioning | RUNTIME-ENV | `ENABLE_SCIM`, `SCIM_TOKEN` |
| Password validation | RUNTIME-ENV | `ENABLE_PASSWORD_VALIDATION`, `PASSWORD_VALIDATION_REGEX_PATTERN` |
| Password hash algorithm | RUNTIME-ENV | `PASSWORD_HASH_ALGORITHM` |
| Admin auto-creation | RUNTIME-ENV | `WEBUI_ADMIN_EMAIL`, `WEBUI_ADMIN_PASSWORD` |
| Default user role | RUNTIME-DB | `DEFAULT_USER_ROLE` |
| Default group | RUNTIME-DB | `DEFAULT_GROUP_ID` |
| Signout redirect | RUNTIME-ENV | `WEBUI_AUTH_SIGNOUT_REDIRECT_URL` |
| Session cookies | RUNTIME-ENV | `WEBUI_SESSION_COOKIE_SAME_SITE`, `WEBUI_SESSION_COOKIE_SECURE` |

---

## 4. UI / Branding / Theming

| Customization | Method | Details |
|---------------|--------|---------|
| Display name | RUNTIME-ENV | `WEBUI_NAME` -- **always appends "(Open WebUI)"** |
| Custom CSS | VOLUME-MOUNT | Mount file at `/app/backend/open_webui/static/custom.css` |
| Custom JS (theme hook) | VOLUME-MOUNT | Mount file at `/app/backend/open_webui/static/loader.js` |
| Logo/favicon override | DERIVED-IMAGE | Replace `/app/build/static/favicon.png`, `/app/build/static/logo.png` (copied to static at startup) |
| Splash screen override | DERIVED-IMAGE | Replace `/app/build/static/splash.png`, `/app/build/static/splash-dark.png` |
| PWA manifest | RUNTIME-ENV | `EXTERNAL_PWA_MANIFEST_URL` |
| Banners | RUNTIME-DB | Admin > General: `WEBUI_BANNERS` |
| Response watermark | RUNTIME-DB | Admin > General: `RESPONSE_WATERMARK` |
| Pending user overlay | RUNTIME-DB | `PENDING_USER_OVERLAY_TITLE`, `PENDING_USER_OVERLAY_CONTENT` |
| Default locale | RUNTIME-DB | `DEFAULT_LOCALE` |
| Default interface settings | RUNTIME-DB | `DEFAULT_INTERFACE_SETTINGS` (JSON) |
| Prompt suggestions | RUNTIME-DB | `DEFAULT_PROMPT_SUGGESTIONS` |
| Easter eggs | RUNTIME-ENV | `ENABLE_EASTER_EGGS` |
| Remove "(Open WebUI)" suffix | FORK | Hardcoded in `env.py` line 938 |
| Change APP_NAME | FORK | Hardcoded in `src/lib/constants.ts` |
| Modify Tailwind theme | FORK | `src/tailwind.css`, `tailwind.config.js` (compiled at build) |
| Add/modify i18n translations | FORK | `src/lib/i18n/locales/` (compiled into SPA) |
| Custom UI components | FORK | SvelteKit components, no plugin API |
| Custom routes/pages | FORK | SvelteKit routes (`src/routes/`) |
| Modify sidebar/layout | FORK | Svelte layout components |
| Full white-label | FORK + LICENSE | Enterprise license required |

---

## 5. Data Backends

| Customization | Method | Details |
|---------------|--------|---------|
| PostgreSQL | RUNTIME-ENV | `DATABASE_URL` or `DATABASE_TYPE` + `DATABASE_HOST` + `DATABASE_PORT` + `DATABASE_NAME` + `DATABASE_USER` + `DATABASE_PASSWORD` |
| SQLCipher | RUNTIME-ENV | `DATABASE_TYPE=sqlite+sqlcipher` |
| DB pool tuning | RUNTIME-ENV | `DATABASE_POOL_SIZE`, `DATABASE_POOL_MAX_OVERFLOW`, `DATABASE_POOL_TIMEOUT`, `DATABASE_POOL_RECYCLE` |
| SQLite WAL/PRAGMA tuning | RUNTIME-ENV | `DATABASE_ENABLE_SQLITE_WAL`, `DATABASE_SQLITE_PRAGMA_*` |
| DB schema (Postgres) | RUNTIME-ENV | `DATABASE_SCHEMA` |
| IAM token auth (RDS) | RUNTIME-ENV | `DATABASE_ENABLE_IAM_TOKEN_AUTH` |
| S3 file storage | RUNTIME-ENV | `STORAGE_PROVIDER=s3`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_BUCKET_NAME`, `S3_ENDPOINT_URL` |
| GCS file storage | RUNTIME-ENV | `STORAGE_PROVIDER=gcs`, `GCS_BUCKET_NAME`, `GOOGLE_APPLICATION_CREDENTIALS_JSON` |
| Azure Blob storage | RUNTIME-ENV | `STORAGE_PROVIDER=azure`, `AZURE_STORAGE_ENDPOINT`, `AZURE_STORAGE_CONTAINER_NAME`, `AZURE_STORAGE_KEY` |
| Vector DB backend | RUNTIME-ENV | `VECTOR_DB` = `chroma` / `qdrant` / `milvus` / `pgvector` / `pinecone` / `opensearch` / `elasticsearch` / `weaviate` / `valkey` / `oracle23ai` / `mariadb-vector` / `opengauss` / `s3vector` |
| Redis (websockets/sessions) | RUNTIME-ENV | `REDIS_URL`, `WEBSOCKET_MANAGER=redis` |
| Redis Sentinel | RUNTIME-ENV | `REDIS_SENTINEL_HOSTS`, `REDIS_SENTINEL_PORT` |

---

## 6. RAG / Knowledge / Search

| Customization | Method | Details |
|---------------|--------|---------|
| Embedding engine | RUNTIME-DB | `RAG_EMBEDDING_ENGINE` (local, openai, ollama, azure) |
| Embedding model | RUNTIME-DB | `RAG_EMBEDDING_MODEL` |
| Reranking engine/model | RUNTIME-DB | `RAG_RERANKING_ENGINE`, `RAG_RERANKING_MODEL` |
| Chunk size/overlap | RUNTIME-DB | `CHUNK_SIZE`, `CHUNK_OVERLAP` |
| RAG template | RUNTIME-DB | `RAG_TEMPLATE` |
| Top-K / relevance threshold | RUNTIME-DB | `RAG_TOP_K`, `RAG_RELEVANCE_THRESHOLD` |
| Hybrid search | RUNTIME-DB | `ENABLE_RAG_HYBRID_SEARCH` |
| Web search engine | RUNTIME-DB | `WEB_SEARCH_ENGINE` (google_pse, brave, searxng, tavily, bing, etc.) |
| Web search enable | RUNTIME-DB | `ENABLE_WEB_SEARCH` |
| Content extraction engine | RUNTIME-DB | `CONTENT_EXTRACTION_ENGINE` (default, tika, docling, mineru, datalab, etc.) |
| File size/count limits | RUNTIME-DB | `RAG_FILE_MAX_SIZE`, `RAG_FILE_MAX_COUNT` |
| Allowed file extensions | RUNTIME-DB | `RAG_ALLOWED_FILE_EXTENSIONS` |
| YouTube loader | RUNTIME-DB | `YOUTUBE_LOADER_LANGUAGE`, `YOUTUBE_LOADER_PROXY_URL` |
| Playwright web loader | RUNTIME-ENV / RUNTIME-DB | `WEB_LOADER_ENGINE=playwright`, `PLAYWRIGHT_WS_URL` |
| Firecrawl web loader | RUNTIME-DB | `FIRECRAWL_API_KEY`, `FIRECRAWL_API_BASE_URL` |

---

## 7. Audio / Images / Code Execution

| Customization | Method | Details |
|---------------|--------|---------|
| STT engine | RUNTIME-DB | `AUDIO_STT_ENGINE` (whisper, openai, azure, deepgram, mistral) |
| TTS engine | RUNTIME-DB | `AUDIO_TTS_ENGINE` (openai, azure, mistral) |
| Image generation engine | RUNTIME-DB | `IMAGE_GENERATION_ENGINE` (openai, automatic1111, comfyui, gemini) |
| Image generation enable | RUNTIME-DB | `ENABLE_IMAGE_GENERATION` |
| Code execution engine | RUNTIME-DB | `CODE_EXECUTION_ENGINE` (pyodide, jupyter) |
| Jupyter URL/auth | RUNTIME-DB | `CODE_EXECUTION_JUPYTER_URL`, `CODE_EXECUTION_JUPYTER_AUTH_TOKEN` |
| Code interpreter | RUNTIME-DB | `ENABLE_CODE_INTERPRETER`, `CODE_INTERPRETER_ENGINE` |
| Code interpreter prompt | RUNTIME-DB | `CODE_INTERPRETER_PROMPT_TEMPLATE` |

---

## 8. Events / Webhooks / Observability

| Customization | Method | Details |
|---------------|--------|---------|
| Webhook URL (legacy) | RUNTIME-DB | `WEBHOOK_URL` |
| Event webhooks | RUNTIME-DB | Admin > General: per-event webhook URLs |
| User webhooks | RUNTIME-DB | `ENABLE_USER_WEBHOOKS` |
| OpenTelemetry | RUNTIME-ENV | `ENABLE_OTEL`, `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_SERVICE_NAME` |
| OTEL traces/metrics/logs | RUNTIME-ENV | `ENABLE_OTEL_TRACES`, `ENABLE_OTEL_METRICS`, `ENABLE_OTEL_LOGS` |
| Audit logging | RUNTIME-ENV | `AUDIT_LOG_LEVEL` (NONE, METADATA, REQUEST, REQUEST_RESPONSE) |
| Audit log file | RUNTIME-ENV | `AUDIT_LOGS_FILE_PATH`, `AUDIT_LOG_FILE_ROTATION_SIZE` |
| Audit stdout | RUNTIME-ENV | `ENABLE_AUDIT_STDOUT` |
| JSON log format | RUNTIME-ENV | `LOG_FORMAT=json` |
| Global log level | RUNTIME-ENV | `GLOBAL_LOG_LEVEL` |

---

## 9. Feature Flags

| Flag | Method | Default |
|------|--------|---------|
| `ENABLE_SIGNUP` | RUNTIME-DB | true |
| `ENABLE_PLUGINS` | RUNTIME-ENV | true |
| `ENABLE_WEB_SEARCH` | RUNTIME-DB | false |
| `ENABLE_IMAGE_GENERATION` | RUNTIME-DB | false |
| `ENABLE_MEMORIES` | RUNTIME-DB | true |
| `ENABLE_CODE_EXECUTION` | RUNTIME-DB | true |
| `ENABLE_CODE_INTERPRETER` | RUNTIME-DB | true |
| `ENABLE_CHANNELS` | RUNTIME-DB | false |
| `ENABLE_NOTES` | RUNTIME-DB | false |
| `ENABLE_FOLDERS` | RUNTIME-DB | true |
| `ENABLE_CALENDAR` | RUNTIME-DB | false |
| `ENABLE_AUTOMATIONS` | RUNTIME-DB | false |
| `ENABLE_SUBAGENTS` | RUNTIME-DB | false |
| `ENABLE_COMMUNITY_SHARING` | RUNTIME-DB | true |
| `ENABLE_MESSAGE_RATING` | RUNTIME-DB | true |
| `ENABLE_FOLLOW_UP_GENERATION` | RUNTIME-DB | true |
| `ENABLE_TITLE_GENERATION` | RUNTIME-DB | true |
| `ENABLE_TAGS_GENERATION` | RUNTIME-DB | true |
| `ENABLE_AUTOCOMPLETE_GENERATION` | RUNTIME-DB | false |
| `ENABLE_CONTEXT_COMPACTION` | RUNTIME-DB | false |
| `ENABLE_USER_STATUS` | RUNTIME-DB | false |
| `ENABLE_EVALUATION_ARENA_MODELS` | RUNTIME-DB | false |
| `ENABLE_VERSION_UPDATE_CHECK` | RUNTIME-ENV | true |
| `ENABLE_DIRECT_CONNECTIONS` | RUNTIME-DB | false |
| `OFFLINE_MODE` | RUNTIME-ENV | false |
| `ENABLE_FORWARD_USER_INFO_HEADERS` | RUNTIME-ENV | false |

---

## 10. Infrastructure / Networking

| Customization | Method | Details |
|---------------|--------|---------|
| Listen port | RUNTIME-ENV | `PORT` (default 8080) |
| Listen host | RUNTIME-ENV | `HOST` (default 0.0.0.0) |
| Uvicorn workers | RUNTIME-ENV | `UVICORN_WORKERS` |
| WebSocket per-message deflate | RUNTIME-ENV | `UVICORN_WS_PER_MESSAGE_DEFLATE` |
| Forwarded IPs | RUNTIME-ENV | `FORWARDED_ALLOW_IPS` |
| HTTP timeout | RUNTIME-ENV | `AIOHTTP_CLIENT_TIMEOUT` |
| Stream idle timeout | RUNTIME-ENV | `AIOHTTP_CLIENT_STREAM_IDLE_TIMEOUT` |
| Connection pool | RUNTIME-ENV | `AIOHTTP_POOL_CONNECTIONS`, `AIOHTTP_POOL_CONNECTIONS_PER_HOST` |
| SSL CA bundle | RUNTIME-ENV | `AIOHTTP_CLIENT_SSL_CERT_FILE` |
| CORS | RUNTIME-ENV | Built-in CORS middleware (configured in `main.py`) |
| Compression middleware | RUNTIME-ENV | `ENABLE_COMPRESSION_MIDDLEWARE` |
| WebUI URL | RUNTIME-DB | `WEBUI_URL` |

---

## Summary Statistics

| Method | Count | Feasibility |
|--------|-------|-------------|
| RUNTIME-ENV | ~120+ | Use upstream image as-is |
| RUNTIME-DB | ~200+ | Use upstream image as-is, configure via Admin UI |
| VOLUME-MOUNT | 2 | Use upstream image as-is, mount files |
| SIDECAR | 3+ | Use upstream image as-is, add companion services |
| DERIVED-IMAGE | ~5 | Build thin layer on top of upstream |
| FORK | ~10 | Requires source modification and rebuild |

**Verdict**: The vast majority of customizations (90%+) can be done without touching
the upstream image. The remaining ~10% are frontend/branding and custom
backend endpoints, which require either a derived image or a fork.

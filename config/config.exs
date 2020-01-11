#                                 .i;;;;i.
#                               iYcviii;vXY:
#                             .YXi       .i1c.
#                            .YC.     .    in7.
#                           .vc.   ......   ;1c.
#                           i7,   ..        .;1;
#                          i7,   .. ...      .Y1i
#                         ,7v     .6MMM@;     .YX,
#                        .7;.   ..IMMMMMM1     :t7.
#                       .;Y.     ;$MMMMMM9.     :tc.
#                       vY.   .. .nMMM@MMU.      ;1v.
#                      i7i   ...  .#MM@M@C. .....:71i
#                     it:   ....   $MMM@9;.,i;;;i,;tti
#                    :t7.  .....   0MMMWv.,iii:::,,;St.
#                   .nC.   .....   IMMMQ..,::::::,.,czX.
#                  .ct:   ....... .ZMMMI..,:::::::,,:76Y.
#                  c2:   ......,i..Y$M@t..:::::::,,..inZY
#                 vov   ......:ii..c$MBc..,,,,,,,,,,..iI9i
#                i9Y   ......iii:..7@MA,..,,,,,,,,,....;AA:
#               iIS.  ......:ii::..;@MI....,............;Ez.
#              .I9.  ......:i::::...8M1..................C0z.
#             .z9;  ......:i::::,.. .i:...................zWX.
#             vbv  ......,i::::,,.      ................. :AQY
#            c6Y.  .,...,::::,,..:t0@@QY. ................ :8bi
#           :6S. ..,,...,:::,,,..EMMMMMMI. ............... .;bZ,
#          :6o,  .,,,,..:::,,,..i#MMMMMM#v.................  YW2.
#         .n8i ..,,,,,,,::,,,,.. tMMMMM@C:.................. .1Wn
#         7Uc. .:::,,,,,::,,,,..   i1t;,..................... .UEi
#         7C...::::::::::::,,,,..        ....................  vSi.
#         ;1;...,,::::::,.........       ..................    Yz:
#          v97,.........                                     .voC.
#           izAotX7777777777777777777777777777777777777777Y7n92:
#             .;CoIIIIIUAA666666699999ZZZZZZZZZZZZZZZZZZZZ6ov.
#
#                          !!! ATTENTION !!!
# DO NOT EDIT THIS FILE! THIS FILE CONTAINS THE DEFAULT VALUES FOR THE CON-
# FIGURATION! EDIT YOUR SECRET FILE (either prod.secret.exs, dev.secret.exs).
#
# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :pleroma, ecto_repos: [Pleroma.Repo]

config :pleroma, Pleroma.Repo,
  types: Pleroma.PostgresTypes,
  telemetry_event: [Pleroma.Repo.Instrumenter],
  migration_lock: nil

scheduled_jobs =
  with digest_config <- Application.get_env(:pleroma, :email_notifications)[:digest],
       true <- digest_config[:active] do
    [{digest_config[:schedule], {Pleroma.Daemons.DigestEmailDaemon, :perform, []}}]
  else
    _ -> []
  end

config :pleroma, Pleroma.Scheduler,
  global: true,
  overlap: true,
  timezone: :utc,
  jobs: scheduled_jobs

config :pleroma, Pleroma.Captcha,
  enabled: true,
  seconds_valid: 300,
  method: Pleroma.Captcha.Native

config :pleroma, Pleroma.Captcha.Kocaptcha, endpoint: "https://captcha.kotobank.ch"

config :pleroma, :hackney_pools,
  federation: [
    max_connections: 50,
    timeout: 150_000
  ],
  media: [
    max_connections: 50,
    timeout: 150_000
  ],
  upload: [
    max_connections: 25,
    timeout: 300_000
  ]

# Upload configuration
config :pleroma, Pleroma.Upload,
  uploader: Pleroma.Uploaders.Local,
  filters: [Pleroma.Upload.Filter.Dedupe],
  link_name: false,
  proxy_remote: false,
  proxy_opts: [
    redirect_on_failure: false,
    max_body_length: 25 * 1_048_576,
    http: [
      follow_redirect: true,
      pool: :upload
    ]
  ]

config :pleroma, Pleroma.Uploaders.Local, uploads: "uploads"

config :pleroma, Pleroma.Uploaders.S3,
  bucket: nil,
  streaming_enabled: true,
  public_endpoint: "https://s3.amazonaws.com"

config :pleroma, :emoji,
  shortcode_globs: ["/emoji/custom/**/*.png"],
  pack_extensions: [".png", ".gif"],
  groups: [
    # Put groups that have higher priority than defaults here. Example in `docs/config/custom_emoji.md`
    Custom: ["/emoji/*.png", "/emoji/**/*.png"]
  ],
  default_manifest: "https://git.pleroma.social/pleroma/emoji-index/raw/master/index.json",
  shared_pack_cache_seconds_per_file: 60

config :pleroma, :uri_schemes,
  valid_schemes: [
    "https",
    "http",
    "dat",
    "dweb",
    "gopher",
    "ipfs",
    "ipns",
    "irc",
    "ircs",
    "magnet",
    "mailto",
    "mumble",
    "ssb",
    "xmpp"
  ]

websocket_config = [
  path: "/websocket",
  serializer: [
    {Phoenix.Socket.V1.JSONSerializer, "~> 1.0.0"},
    {Phoenix.Socket.V2.JSONSerializer, "~> 2.0.0"}
  ],
  timeout: 60_000,
  transport_log: false,
  compress: false
]

# Configures the endpoint
config :pleroma, Pleroma.Web.Endpoint,
  instrumenters: [Pleroma.Web.Endpoint.Instrumenter],
  url: [host: "localhost"],
  http: [
    ip: {127, 0, 0, 1},
    dispatch: [
      {:_,
       [
         {"/api/v1/streaming", Pleroma.Web.MastodonAPI.WebsocketHandler, []},
         {"/websocket", Phoenix.Endpoint.CowboyWebSocket,
          {Phoenix.Transports.WebSocket,
           {Pleroma.Web.Endpoint, Pleroma.Web.UserSocket, websocket_config}}},
         {:_, Phoenix.Endpoint.Cowboy2Handler, {Pleroma.Web.Endpoint, []}}
       ]}
    ]
  ],
  protocol: "https",
  secret_key_base: "aK4Abxf29xU9TTDKre9coZPUgevcVCFQJe/5xP/7Lt4BEif6idBIbjupVbOrbKxl",
  signing_salt: "CqaoopA2",
  render_errors: [view: Pleroma.Web.ErrorView, accepts: ~w(json)],
  pubsub: [name: Pleroma.PubSub, adapter: Phoenix.PubSub.PG2],
  secure_cookie_flag: true,
  extra_cookie_attrs: [
    "SameSite=Lax"
  ]

# Configures Elixir's Logger
config :logger, :console,
  level: :debug,
  format: "\n$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger, :ex_syslogger,
  level: :debug,
  ident: "pleroma",
  format: "$metadata[$level] $message",
  metadata: [:request_id]

config :quack,
  level: :warn,
  meta: [:all],
  webhook_url: "https://hooks.slack.com/services/YOUR-KEY-HERE"

config :mime, :types, %{
  "application/xml" => ["xml"],
  "application/xrd+xml" => ["xrd+xml"],
  "application/jrd+json" => ["jrd+json"],
  "application/activity+json" => ["activity+json"],
  "application/ld+json" => ["activity+json"]
}

config :tesla, adapter: Tesla.Adapter.Hackney

# Configures http settings, upstream proxy etc.
config :pleroma, :http,
  proxy_url: nil,
  send_user_agent: true,
  user_agent: :default,
  adapter: [
    ssl_options: [
      # Workaround for remote server certificate chain issues
      partial_chain: &:hackney_connect.partial_chain/1,
      # We don't support TLS v1.3 yet
      versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"]
    ]
  ]

config :pleroma, :instance,
  name: "Pleroma",
  email: "example@example.com",
  notify_email: "noreply@example.com",
  description: "A Pleroma instance, an alternative fediverse server",
  limit: 5_000,
  chat_limit: 5_000,
  remote_limit: 100_000,
  upload_limit: 16_000_000,
  avatar_upload_limit: 2_000_000,
  background_upload_limit: 4_000_000,
  banner_upload_limit: 4_000_000,
  poll_limits: %{
    max_options: 20,
    max_option_chars: 200,
    min_expiration: 0,
    max_expiration: 365 * 24 * 60 * 60
  },
  registrations_open: true,
  federating: true,
  federation_incoming_replies_max_depth: 100,
  federation_reachability_timeout_days: 7,
  federation_publisher_modules: [
    Pleroma.Web.ActivityPub.Publisher
  ],
  allow_relay: true,
  rewrite_policy: Pleroma.Web.ActivityPub.MRF.NoOpPolicy,
  public: true,
  quarantined_instances: [],
  managed_config: true,
  static_dir: "instance/static/",
  allowed_post_formats: [
    "text/plain",
    "text/html",
    "text/markdown",
    "text/bbcode"
  ],
  mrf_transparency: true,
  mrf_transparency_exclusions: [],
  autofollowed_nicknames: [],
  max_pinned_statuses: 1,
  no_attachment_links: true,
  welcome_user_nickname: nil,
  welcome_message: nil,
  max_report_comment_size: 1000,
  safe_dm_mentions: false,
  healthcheck: false,
  remote_post_retention_days: 90,
  skip_thread_containment: true,
  limit_to_local_content: :unauthenticated,
  dynamic_configuration: false,
  user_bio_length: 5000,
  user_name_length: 100,
  max_account_fields: 10,
  max_remote_account_fields: 20,
  account_field_name_length: 512,
  account_field_value_length: 2048,
  external_user_synchronization: true,
  extended_nickname_format: true

config :pleroma, :feed,
  post_title: %{
    max_length: 100,
    omission: "..."
  }

config :pleroma, :markup,
  # XXX - unfortunately, inline images must be enabled by default right now, because
  # of custom emoji.  Issue #275 discusses defanging that somehow.
  allow_inline_images: true,
  allow_headings: false,
  allow_tables: false,
  allow_fonts: false,
  scrub_policy: [
    Pleroma.HTML.Scrubber.Default,
    Pleroma.HTML.Transform.MediaProxy
  ]

config :pleroma, :frontend_configurations,
  pleroma_fe: %{
    theme: "pleroma-dark",
    logo: "/static/logo.png",
    background: "/images/city.jpg",
    redirectRootNoLogin: "/main/all",
    redirectRootLogin: "/main/friends",
    showInstanceSpecificPanel: true,
    scopeOptionsEnabled: false,
    formattingOptionsEnabled: false,
    collapseMessageWithSubject: false,
    hidePostStats: false,
    hideUserStats: false,
    scopeCopy: true,
    subjectLineBehavior: "email",
    alwaysShowSubjectInput: true
  },
  masto_fe: %{
    showInstanceSpecificPanel: true
  }

config :pleroma, :assets,
  mascots: [
    pleroma_fox_tan: %{
      url: "/images/pleroma-fox-tan-smol.png",
      mime_type: "image/png"
    },
    pleroma_fox_tan_shy: %{
      url: "/images/pleroma-fox-tan-shy.png",
      mime_type: "image/png"
    }
  ],
  default_mascot: :pleroma_fox_tan

config :pleroma, :manifest,
  icons: [
    %{
      src: "/static/logo.png",
      type: "image/png"
    }
  ],
  theme_color: "#282c37",
  background_color: "#191b22"

config :pleroma, :activitypub,
  unfollow_blocked: true,
  outgoing_blocks: true,
  follow_handshake_timeout: 500,
  sign_object_fetches: true

config :pleroma, :streamer,
  workers: 3,
  overflow_workers: 2

config :pleroma, :user, deny_follow_blocked: true

config :pleroma, :mrf_normalize_markup, scrub_policy: Pleroma.HTML.Scrubber.Default

config :pleroma, :mrf_rejectnonpublic,
  allow_followersonly: false,
  allow_direct: false

config :pleroma, :mrf_hellthread,
  delist_threshold: 10,
  reject_threshold: 20

config :pleroma, :mrf_simple,
  media_removal: [],
  media_nsfw: [],
  federated_timeline_removal: [],
  report_removal: [],
  reject: [],
  accept: [],
  avatar_removal: [],
  banner_removal: []

config :pleroma, :mrf_keyword,
  reject: [],
  federated_timeline_removal: [],
  replace: []

config :pleroma, :mrf_subchain, match_actor: %{}

config :pleroma, :mrf_vocabulary,
  accept: [],
  reject: []

config :pleroma, :mrf_object_age,
  threshold: 172_800,
  actions: [:delist, :strip_followers]

config :pleroma, :rich_media,
  enabled: true,
  ignore_hosts: [],
  ignore_tld: ["local", "localdomain", "lan"],
  parsers: [
    Pleroma.Web.RichMedia.Parsers.TwitterCard,
    Pleroma.Web.RichMedia.Parsers.OGP,
    Pleroma.Web.RichMedia.Parsers.OEmbed
  ],
  ttl_setters: [Pleroma.Web.RichMedia.Parser.TTL.AwsSignedUrl]

config :pleroma, :media_proxy,
  enabled: false,
  proxy_opts: [
    redirect_on_failure: false,
    max_body_length: 25 * 1_048_576,
    http: [
      follow_redirect: true,
      pool: :media
    ]
  ],
  whitelist: []

config :pleroma, :chat, enabled: true

config :phoenix, :format_encoders, json: Jason

config :phoenix, :json_library, Jason

config :pleroma, :gopher,
  enabled: false,
  ip: {0, 0, 0, 0},
  port: 9999

config :pleroma, Pleroma.Web.Metadata,
  providers: [
    Pleroma.Web.Metadata.Providers.OpenGraph,
    Pleroma.Web.Metadata.Providers.TwitterCard,
    Pleroma.Web.Metadata.Providers.RelMe,
    Pleroma.Web.Metadata.Providers.Feed
  ],
  unfurl_nsfw: false

config :pleroma, :suggestions,
  enabled: false,
  third_party_engine:
    "http://vinayaka.distsn.org/cgi-bin/vinayaka-user-match-suggestions-api.cgi?{{host}}+{{user}}",
  timeout: 300_000,
  limit: 40,
  web: "https://vinayaka.distsn.org"

config :pleroma, :http_security,
  enabled: true,
  sts: false,
  sts_max_age: 31_536_000,
  ct_max_age: 2_592_000,
  referrer_policy: "same-origin"

config :cors_plug,
  max_age: 86_400,
  methods: ["POST", "PUT", "DELETE", "GET", "PATCH", "OPTIONS"],
  expose: [
    "Link",
    "X-RateLimit-Reset",
    "X-RateLimit-Limit",
    "X-RateLimit-Remaining",
    "X-Request-Id",
    "Idempotency-Key"
  ],
  credentials: true,
  headers: ["Authorization", "Content-Type", "Idempotency-Key"]

config :pleroma, Pleroma.User,
  restricted_nicknames: [
    ".well-known",
    "~",
    "about",
    "activities",
    "api",
    "auth",
    "check_password",
    "dev",
    "friend-requests",
    "inbox",
    "internal",
    "main",
    "media",
    "nodeinfo",
    "notice",
    "oauth",
    "objects",
    "ostatus_subscribe",
    "pleroma",
    "proxy",
    "push",
    "registration",
    "relay",
    "settings",
    "status",
    "tag",
    "user-search",
    "user_exists",
    "users",
    "web"
  ]

config :pleroma, Oban,
  repo: Pleroma.Repo,
  verbose: false,
  prune: {:maxlen, 1500},
  queues: [
    activity_expiration: 10,
    federator_incoming: 50,
    federator_outgoing: 50,
    web_push: 50,
    mailer: 10,
    transmogrifier: 20,
    scheduled_activities: 10,
    background: 5
  ]

config :pleroma, :workers,
  retries: [
    federator_incoming: 5,
    federator_outgoing: 5
  ]

config :pleroma, :fetch_initial_posts,
  enabled: false,
  pages: 5

config :auto_linker,
  opts: [
    scheme: true,
    extra: true,
    # TODO: Set to :no_scheme when it works properly
    validate_tld: true,
    class: false,
    strip_prefix: false,
    new_window: false,
    rel: "ugc"
  ]

config :pleroma, :ldap,
  enabled: System.get_env("LDAP_ENABLED") == "true",
  host: System.get_env("LDAP_HOST") || "localhost",
  port: String.to_integer(System.get_env("LDAP_PORT") || "389"),
  ssl: System.get_env("LDAP_SSL") == "true",
  sslopts: [],
  tls: System.get_env("LDAP_TLS") == "true",
  tlsopts: [],
  base: System.get_env("LDAP_BASE") || "dc=example,dc=com",
  uid: System.get_env("LDAP_UID") || "cn"

config :esshd,
  enabled: false

oauth_consumer_strategies =
  System.get_env("OAUTH_CONSUMER_STRATEGIES")
  |> to_string()
  |> String.split()
  |> Enum.map(&hd(String.split(&1, ":")))

ueberauth_providers =
  for strategy <- oauth_consumer_strategies do
    strategy_module_name = "Elixir.Ueberauth.Strategy.#{String.capitalize(strategy)}"
    strategy_module = String.to_atom(strategy_module_name)
    {String.to_atom(strategy), {strategy_module, [callback_params: ["state"]]}}
  end

config :ueberauth,
       Ueberauth,
       base_path: "/oauth",
       providers: ueberauth_providers

config :pleroma,
       :auth,
       enforce_oauth_admin_scope_usage: false,
       oauth_consumer_strategies: oauth_consumer_strategies

config :pleroma, Pleroma.Emails.Mailer, adapter: Swoosh.Adapters.Sendmail, enabled: false

config :pleroma, Pleroma.Emails.UserEmail,
  logo: nil,
  styling: %{
    link_color: "#d8a070",
    background_color: "#2C3645",
    content_background_color: "#1B2635",
    header_color: "#d8a070",
    text_color: "#b9b9ba",
    text_muted_color: "#b9b9ba"
  }

config :prometheus, Pleroma.Web.Endpoint.MetricsExporter, path: "/api/pleroma/app_metrics"

config :pleroma, Pleroma.ScheduledActivity,
  daily_user_limit: 25,
  total_user_limit: 300,
  enabled: true

config :pleroma, :email_notifications,
  digest: %{
    active: false,
    schedule: "0 0 * * 0",
    interval: 7,
    inactivity_threshold: 7
  }

config :pleroma, :oauth2,
  token_expires_in: 600,
  issue_new_refresh_token: true,
  clean_expired_tokens: false,
  clean_expired_tokens_interval: 86_400_000

config :pleroma, :database, rum_enabled: false

config :pleroma, :env, Mix.env()

config :http_signatures,
  adapter: Pleroma.Signature

config :pleroma, :rate_limit, authentication: {60_000, 15}

config :pleroma, Pleroma.ActivityExpiration, enabled: true

config :pleroma, Pleroma.Plugs.RemoteIp, enabled: false

config :pleroma, :static_fe, enabled: false

config :pleroma, :web_cache_ttl,
  activity_pub: nil,
  activity_pub_question: 30_000

config :pleroma, :modules, runtime_dir: "instance/modules"

config :swarm, node_blacklist: [~r/myhtml_.*$/]
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

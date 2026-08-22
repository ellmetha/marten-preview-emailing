PREVIEW_EMAILS_LOCATION = Path[File.tempname("marten_preview_emailing")]

Marten.configure :test do |config|
  config.emailing.backend = MartenPreviewEmailing::Backend.new(PREVIEW_EMAILS_LOCATION)
  config.installed_apps = [
    MartenPreviewEmailing::App,
  ]
  config.log_level = ::Log::Severity::None
  config.secret_key = "__insecure_#{Random::Secure.random_bytes(32).hexstring}__"
end

Marten.routes.draw do
  path "/emails", MartenPreviewEmailing::ROUTES, name: "preview_emailing"
end

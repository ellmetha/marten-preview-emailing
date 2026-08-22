# Marten Preview Emailing

**Marten Preview Emailing** provides a development emailing backend that collects sent emails so they can be previewed
in the browser.

## Installation

Simply add the following entry to your project's `shard.yml`:

```yaml
dependencies:
  marten_preview_emailing:
    github: martenframework/marten-preview-emailing
```

And run `shards install` afterward.

## Configuration

First, add the following requirement to your project's `src/project.cr` file:

```crystal
require "marten_preview_emailing"
```

You can then configure your project to use the preview backend by setting the corresponding configuration option as
follows, and by adding the `MartenPreviewEmailing::App` application to your `installed_apps` setting:

```crystal
Marten.configure do |config|
  config.installed_apps = [
    MartenPreviewEmailing::App,
    # Other apps...
  ]

  config.emailing.backend = MartenPreviewEmailing::Backend.new
end
```

By default, delivered emails are stored under `MartenPreviewEmailing::DEFAULT_EMAILS_LOCATION` (relative to your
project root). You can customize this location at initialization time by passing a relative path as a string:

```crystal
Marten.configure do |config|
  config.emailing.backend = MartenPreviewEmailing::Backend.new("tmp/custom-emails")
end
```

You can also pass an absolute `Path` if you need to store previews outside of the project:

```crystal
Marten.configure do |config|
  config.emailing.backend = MartenPreviewEmailing::Backend.new(Path["/tmp/marten-emails"])
end
```

## Browsing collected emails

Mount the provided routes map in your project's `config/routes.cr` file (typically in development only):

```crystal
Marten.routes.draw do
  if Marten.env.development?
    path "/emails", MartenPreviewEmailing::ROUTES, name: "preview_emailing"
  end
end
```

You can then browse collected emails at `http://localhost:8000/emails`. Each delivered email is also written to a
dedicated directory containing `rich.html` (HTML part) and/or `plain.html` (text part), plus any attachments.

## Authors

Morgan Aubert ([@ellmetha](https://github.com/ellmetha)) and
[contributors](https://github.com/ellmetha/marten-preview-emailing/contributors).

## License

MIT. See `LICENSE` for more details.

require "./preview_email/*"

module MartenPreviewEmailing
  # A preview email persisted on disk by `Backend`.
  class PreviewEmail
    include Marten::Template::Object

    getter id : String
    getter directory : Path
    getter meta : Meta

    template_attributes(
      :id,
      :subject,
      :from,
      :to,
      :cc,
      :bcc,
      :reply_to,
      :headers,
      :delivered_at,
      :attachments,
      :formatted_date,
      :html_body,
      :text_body,
      :has_html?,
      :has_text?,
      :has_attachments?,
      :has_bcc?,
      :has_cc?,
      :has_reply_to?,
      :has_subject?,
      :has_to?
    )

    # Persists `email` under `directory` and returns the preview email.
    #
    # HTML emails are stored as `rich.html` and text emails as `plain.html`. Attachments are written to an
    # `attachments` subdirectory.
    def self.collect(email : Marten::Emailing::Email, directory : Path) : self
      html_body = email.html_body
      text_body = email.text_body
      delivered_at = Time.local

      Dir.mkdir_p(directory)
      attachments = persist_attachments(email, directory)
      persist_bodies(directory, html_body, text_body)

      meta = Meta.new(
        subject: email.subject.to_s,
        from: email.from.to_s,
        to: format_addresses(email.to),
        cc: format_addresses(email.cc),
        bcc: format_addresses(email.bcc),
        reply_to: email.reply_to.try(&.to_s).to_s,
        headers: email.headers,
        delivered_at: delivered_at,
        has_html: !html_body.nil?,
        has_text: !text_body.nil?,
        attachments: attachments.map do |filename, path|
          AttachmentRef.new(filename, path)
        end
      )

      File.write(directory.join("meta.json"), meta.to_json)

      preview = new(directory.basename, directory, meta)
      render_preview_files(preview)
      preview
    end

    # Returns preview emails under `location`, newest first.
    #
    # When `location` is omitted, `#emails_location` is used.
    def self.all(location : Path = MartenPreviewEmailing.emails_location) : Array(self)
      return [] of self unless Dir.exists?(location)

      Dir.children(location.to_s).compact_map do |name|
        find(location, name)
      end.sort_by!(&.delivered_at).reverse!
    end

    # Returns the preview email identified by `id`, or `nil` if it cannot be found.
    def self.find(location : Path, id : String) : self?
      return unless valid_id?(id)

      directory = location.join(id).expand
      return unless directory.to_s.starts_with?(location.expand.to_s)
      return unless File.directory?(directory)

      meta_path = directory.join("meta.json")
      return unless File.exists?(meta_path)

      new(id, directory, Meta.from_json(File.read(meta_path)))
    end

    # Deletes all preview emails under `location`.
    #
    # When `location` is omitted, `#emails_location` is used.
    def self.delete_all(location : Path = MartenPreviewEmailing.emails_location) : Nil
      return unless Dir.exists?(location)

      Dir.children(location.to_s).each do |name|
        find(location, name).try(&.delete)
      end
    end

    def self.valid_id?(id : String) : Bool
      !id.includes?("..") && !!(id =~ /\A[A-Za-z0-9._-]+\z/)
    end

    def initialize(@id : String, @directory : Path, @meta : Meta)
    end

    delegate subject, from, to, cc, bcc, reply_to, headers, delivered_at, attachments, to: meta
    delegate has_html?, has_text?, to: meta

    def has_attachments? : Bool
      !attachments.empty?
    end

    def has_bcc? : Bool
      !bcc.empty?
    end

    def has_cc? : Bool
      !cc.empty?
    end

    def has_reply_to? : Bool
      !reply_to.empty?
    end

    def has_subject? : Bool
      !subject.empty?
    end

    def has_to? : Bool
      !to.empty?
    end

    # Returns the path of an attachment file if it exists within this email directory.
    def attachment_path(filename : String) : Path?
      safe_name = Path[filename].basename
      return if safe_name != filename || safe_name.includes?("..")

      attachments_dir = directory.join("attachments").expand
      path = attachments_dir.join(safe_name).expand
      return unless path.to_s.starts_with?(attachments_dir.to_s)
      return unless File.file?(path)

      path
    end

    # Returns the formatted delivery timestamp.
    def formatted_date : String
      delivered_at.to_s("%b %e, %Y %I:%M:%S %P %Z")
    end

    # Returns the HTML body if one was collected.
    def html_body : String?
      read_optional(directory.join("body.html"))
    end

    # Returns the body to display for the HTML or text part of the email.
    def preview_body(html : Bool)
      if html
        html_body.to_s
      else
        Marten::Template::SafeString.new(auto_link(HTML.escape(text_body.to_s)))
      end
    end

    # Returns the text body if one was collected.
    def text_body : String?
      read_optional(directory.join("body.txt"))
    end

    # Deletes this preview email from disk.
    def delete : Nil
      FileUtils.rm_rf(directory)
    end

    private FILE_TEMPLATE_NAME = "marten_preview_emailing/email_file.html"

    private def self.format_addresses(addresses : Array(Marten::Emailing::Address)?) : String
      return "" if addresses.nil?

      addresses.map(&.to_s).join(", ")
    end

    private def self.persist_attachments(
      email : Marten::Emailing::Email,
      directory : Path,
    ) : Array({String, String})
      return [] of {String, String} if email.attachments.empty?

      attachments_dir = directory.join("attachments")
      Dir.mkdir_p(attachments_dir)

      email.attachments.map do |attachment|
        filename = sanitize_filename(attachment.filename)
        File.write(attachments_dir.join(filename), attachment.content)
        {attachment.filename, "attachments/#{filename}"}
      end
    end

    private def self.persist_bodies(directory : Path, html_body : String?, text_body : String?) : Nil
      File.write(directory.join("body.html"), html_body) unless html_body.nil?
      File.write(directory.join("body.txt"), text_body) unless text_body.nil?
    end

    private def self.sanitize_filename(filename : String) : String
      Path[filename].basename.tr("\u{202E}%$|:;/\t\r\n\\", "-")
    end

    private def auto_link(text : String) : String
      text.gsub(%r{(https?://[^\s<]+)}) do |url|
        %(<a href="#{url}">#{url}</a>)
      end
    end

    private def self.preview_file_html(preview : self, html : Bool) : String
      Marten.templates.get_template(FILE_TEMPLATE_NAME).render({
        email: preview,
        html:  html,
        body:  preview.preview_body(html),
      })
    end

    private def self.render_preview_file(preview : self, html : Bool) : Nil
      filename = html ? "rich.html" : "plain.html"
      File.write(preview.directory.join(filename), preview_file_html(preview, html))
    end

    private def self.render_preview_files(preview : self) : Nil
      render_preview_file(preview, html: true) if preview.has_html?
      render_preview_file(preview, html: false) if preview.has_text?
      render_preview_file(preview, html: false) unless preview.has_html? || preview.has_text?
    end

    private def read_optional(path : Path) : String?
      File.exists?(path) ? File.read(path) : nil
    end
  end
end

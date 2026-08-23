module MartenPreviewEmailing
  # Serves an attachment associated with a collected email.
  class EmailAttachmentHandler < Marten::Handler
    http_method_names :get

    def get
      email = PreviewEmail.find(MartenPreviewEmailing.emails_location, params["id"].to_s)
      raise Marten::HTTP::Errors::NotFound.new("Email not found") if email.nil?

      path = email.attachment_path(params["filename"].to_s)
      raise Marten::HTTP::Errors::NotFound.new("Attachment not found") if path.nil?

      content = File.open(path) { |file| String.new(file.getb_to_end) }
      filename = Path[path].basename

      response = respond(content, content_type: mime_type(filename))
      response["Content-Disposition"] = %(inline; filename="#{filename}")
      response
    end

    private def mime_type(filename : String) : String
      MIME.from_filename(filename, "application/octet-stream")
    end
  end
end

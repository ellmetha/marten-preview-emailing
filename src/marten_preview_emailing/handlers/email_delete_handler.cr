module MartenPreviewEmailing
  # Deletes a single preview email.
  class EmailDeleteHandler < Marten::Handler
    http_method_names :post

    def post
      email = PreviewEmail.find(MartenPreviewEmailing.emails_location, params["id"].to_s)
      raise Marten::HTTP::Errors::NotFound.new("Email not found") if email.nil?

      email.delete

      redirect(Marten.routes.reverse("preview_emailing:list"))
    end
  end
end

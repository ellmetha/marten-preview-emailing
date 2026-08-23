module MartenPreviewEmailing
  # Deletes all preview emails.
  class EmailClearHandler < Marten::Handler
    http_method_names :post

    def post
      PreviewEmail.delete_all

      redirect(Marten.routes.reverse("preview_emailing:list"))
    end
  end
end

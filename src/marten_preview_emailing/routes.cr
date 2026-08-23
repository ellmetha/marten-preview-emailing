module MartenPreviewEmailing
  # Routes allowing to browse emails collected by the preview emailing backend.
  #
  # Mount this map in your project's routes (typically in development only):
  #
  # ```
  # Marten.routes.draw do
  #   if Marten.env.development?
  #     path "/emails", MartenPreviewEmailing::ROUTES, name: "preview_emailing"
  #   end
  # end
  # ```
  ROUTES = Marten::Routing::Map.draw(:preview_emailing) do
    path "", EmailListHandler, name: "list"
    path "clear", EmailClearHandler, name: "clear"
    path "/<id:str>/attachments/<filename:str>", EmailAttachmentHandler, name: "attachment"
    path "/<id:str>/delete", EmailDeleteHandler, name: "delete"
    path "/<id:str>", EmailDetailHandler, name: "detail"
  end
end

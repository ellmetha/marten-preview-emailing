module MartenPreviewEmailing
  class PreviewEmail
    # Metadata persisted next to a preview email.
    class Meta
      include JSON::Serializable

      getter subject : String
      getter from : String
      getter to : String
      getter cc : String
      getter bcc : String
      getter reply_to : String
      getter headers : Hash(String, String)
      getter delivered_at : Time
      getter? has_html : Bool
      getter? has_text : Bool
      getter attachments : Array(AttachmentRef)

      def initialize(
        @subject : String,
        @from : String,
        @to : String,
        @cc : String,
        @bcc : String,
        @reply_to : String,
        @headers : Hash(String, String),
        @delivered_at : Time,
        @has_html : Bool,
        @has_text : Bool,
        @attachments : Array(AttachmentRef),
      )
      end
    end
  end
end

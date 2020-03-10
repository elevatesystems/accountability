module Accountability
  class StatementsController < AccountabilityController
    before_action :set_statement

    def download_pdf
      end_date = @statement.end_date.strftime('%B %-d, %Y')
      filename = "Billing Statement - #{end_date}.pdf"
      pdf = StatementPdf.new(@statement)

      send_data pdf.render, filename: filename, type: 'application/pdf'
    end

    private

    def set_statement
      @statement = Statement.find(params[:id])
    end
  end
end

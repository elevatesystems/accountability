module Accountability
  class PaymentsController < AccountabilityController
    before_action :set_account

    def create
      @payment = @account.payments.new(payment_params)

      if @payment.save
        redirect_to accountability_account_path(@account), notice: 'Payment was completed successfully'
      else
        render json: { status: :error, errors: @payment.errors }
      end
    end

    private

    def payment_params
      params.require(:payment).permit(:amount, :billing_configuration_id)
    end

    def set_account
      @account = Account.find(params[:account_id])
    end
  end
end

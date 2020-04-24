module Accountability
  class BillingConfigurationsController < AccountabilityController
    before_action :set_billing_configuration, except: %i[new create]
    before_action :set_account, only: %i[create update designate_as_primary]

    def show; end

    def new; end

    # TODO: Ensure values are not being casted before they reach validations.
    # Specifically, it seems Zip when not a number ends up being casted to 0 and passes validation.
    def create
      bc_params = billing_configuration_params
      @billing_configuration = @account.build_billing_configuration_with_active_merchant_data(bc_params,
                                                                                              verify_card: true)
      if @billing_configuration.save
        message = 'Credit card successfully added.'
        render json: { status: :success, message: message, updated_elements: updated_billing_elements }
      else
        render json: { status: :error, errors: @billing_configuration.errors }
      end
    end

    def edit; end

    def update
      @billing_configuration.update billing_configuration_params

      if @billing_configuration.save
        message = 'Configuration Updated'
        render json: { status: :success, message: message, updated_elements: updated_billing_elements }
      else
        render json: { status: :error, errors: @billing_configuration.errors }
      end
    end

    def destroy
      if @billing_configuration.destroy
        render json: {
          status: :success,
          message: 'Payment Method Destroyed'
        }
      else
        render json: { status: :error, errors: @billing_configuration.errors }
      end
    end

    def designate_as_primary
      if @billing_configuration.primary!
        message = 'Payment Method Set As Primary'
        render json: { status: :success, message: message, updated_elements: updated_billing_elements }
      else
        render json: { status: :error, errors: @billing_configuration.errors }
      end
    end

    def updated_billing_elements
      payment_form_partial = 'accounts/payment_form'
      configurations_partial = 'accounts/billing_configurations/configurations'

      {
        payment_form: safe_render_partial_to_string(payment_form_partial),
        configurations: safe_render_partial_to_string(configurations_partial)
      }
    end

    private

    def safe_render_partial_to_string(partial)
      return unless partial_exists?(partial)

      render_to_string(partial: partial, layout: false, locals: { account: @account })
    end

    def set_billing_configuration
      @billing_configuration = BillingConfiguration.find(params[:id])
    end

    def set_account
      @account = Account.find(params[:account_id])
    end

    def billing_configuration_params
      params.require(:billing_configuration).permit(:token, :configuration_name, :provider, :contact_email,
                                                    :contact_first_name, :contact_last_name, billing_address: {})
    end
  end
end

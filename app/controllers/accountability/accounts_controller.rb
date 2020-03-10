module Accountability
  class AccountsController < AccountabilityController
    before_action :set_account, except: %i[index]

    def index
      @accounts = Account.all
    end

    def show; end

    private

    def set_account
      @account = Account.find(params[:id])
    end
  end
end

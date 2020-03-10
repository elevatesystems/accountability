# New Credit records are automatically assigned to the latest Statement on their associated Account.
# If the latest statement is past its :end_date, the credit will build a new one.
# The new :end_date is determined by the account's :statement_schedule enum.

module Accountability
  class Statement < ApplicationRecord
    self.implicit_order_column = 'end_date'

    before_validation :set_end_date

    belongs_to :account
    has_many :credits, dependent: :destroy

    validates :end_date, presence: true

    delegate :past?, :future?, to: :end_date

    def paid?
      return false if account.last_balanced_at.nil?

      end_date.before? account.last_balanced_at
    end

    def total_accrued
      credits.sum(:amount)
    end

    def transactions
      associated_credits = credits.includes(:product, deductions: :discount).references(:order_item)

      Transactions.new(credits: associated_credits)
    end

    private

    def set_end_date
      return if account.nil?
      return if end_date.present?

      self.end_date = case account.statement_schedule
                      when 'end_of_month' then Time.current.end_of_month
                      when 'bi_weekly' then 2.weeks.from_now
                      end
    end
  end
end

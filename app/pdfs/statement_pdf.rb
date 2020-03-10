require 'prawn'
require 'prawn/table'
require 'date'

class StatementPdf
  include ActiveSupport::NumberHelper
  include Prawn::View

  attr_accessor :statement

  def initialize(statement, debug_mode: false)
    @statement = statement
    @debug_mode = debug_mode

    draw_document
  end

  def draw_document
    font 'Helvetica'

    stroke_axis if debug_mode?
    draw_header
    move_down 40
    draw_transactions_section
    number_pages '<page>', align: :center, at: [0, -6]
  end

  def draw_header
    # Draw upper-left text
    bounding_box [0, 720], width: 250, height: 70 do
      move_down 10
      text 'STATEMENT', size: 18
      move_down 5
      text "Ending: #{statement.end_date.strftime('%B %-d, %Y')}", align: :left

      transparent(0.5) { stroke_bounds } if debug_mode?
    end

    # Draw upper-right logo
    bounding_box [290, 720], width: 250, height: 70 do
      logo_path = Accountability::Configuration.logo_path
      image logo_path, fit: [250, 70], position: :right
      transparent(0.5) { stroke_bounds } if debug_mode?
    end
  end

  def draw_transactions_section
    text 'Details', style: :bold_italic
    stroke_horizontal_rule
    move_down 15

    # Draw transactions table
    transactions = Accountability::Transactions.new(credits: statement.credits.includes(:product, :deductions))
    transaction_data = transactions.sort_by(&:date).reverse.map do |transaction|
      [transaction.date.strftime('%b %-d, %Y'), make_transaction_subtable(transaction)]
    end

    table transaction_data, column_widths: [100, 440], row_colors: %w[d2e3ed ffffff]

    # Draw statement total in separate table
    total_data = [[nil, 'Total ', decorate_currency(statement.total_accrued)]]
    table total_data, cell_style: { borders: [], font_style: :bold }, column_widths: [100, 340, 100] do
      row(-1).columns(1).style align: :right
      row(-1).columns(2).borders = %i[bottom left right]
    end
  end

  def make_transaction_subtable(transaction)
    rows = [[transaction.description, decorate_currency(transaction.base_amount)]]

    # Define deduction rows if applicable
    transaction.deductions.each do |deduction|
      rows.append([deduction.coupon_name, decorate_currency(-deduction.amount)])
    end

    # Define tax row if applicable
    rows.append(['Tax', decorate_currency(transaction.taxes)]) if transaction.taxes.nonzero?

    make_table rows, column_widths: [340, 100]
  end

  private

  def debug_mode?
    @debug_mode
  end

  def decorate_currency(value)
    number_to_currency value, negative_format: '(%u%n)'
  end
end

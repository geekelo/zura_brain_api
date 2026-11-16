class Admin::MainAccountExpensesController < ApplicationController
  def create
    expense = MainAccountExpense.new(main_account_expense_params)
    if expense.save
      refresh_main_account(expense)
      render json: expense, status: :created
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    expense = set_main_account_expense
    return if expense.nil?

    if expense.update(main_account_expense_params)
      refresh_main_account(expense)
      render json: expense, status: :ok
    else
      render json: { errors: expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    expense = set_main_account_expense
    return if expense.nil?

    created_at = expense.created_at
    expense.destroy
    Pos::UpdateMainAccount.call(month: created_at.month, year: created_at.year)
    render json: { message: "Main account expense deleted successfully" }, status: :ok
  end

  private

  def main_account_expense_params
    params.require(:main_account_expense).permit(:description, :amount)
  end

  def set_main_account_expense
    expense = MainAccountExpense.find_by(id: params[:id])
    if expense.nil?
      render json: { error: "Main account expense not found" }, status: :not_found
      return
    end
    expense
  end

  def refresh_main_account(expense)
    Pos::UpdateMainAccount.call(month: expense.created_at.month, year: expense.created_at.year)
  end
end

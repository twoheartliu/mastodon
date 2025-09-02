# frozen_string_literal: true

class Vacuum::ImportsVacuum
  def perform
    clean_unconfirmed_imports!
    clean_old_imports!
  end

  private

  def clean_unconfirmed_imports!
<<<<<<< HEAD
    BulkImport.state_unconfirmed.where(created_at: ..10.minutes.ago).in_batches.delete_all
  end

  def clean_old_imports!
    BulkImport.where(created_at: ..1.week.ago).in_batches.delete_all
=======
    BulkImport
      .confirmation_missed
      .in_batches
      .delete_all
  end

  def clean_old_imports!
    BulkImport
      .archival_completed
      .in_batches
      .delete_all
>>>>>>> v4.4.3
  end
end

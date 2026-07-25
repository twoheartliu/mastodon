# frozen_string_literal: true

Fabricator(:on_this_day_record) do
  account
  date { OnThisDay.today_cst }
  data { { 'years' => {} } }
end

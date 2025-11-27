# frozen_string_literal: true

require 'csv'

module Admin
  class SchoolImportResultsController < Admin::ApplicationController
    def index
      search_term = params[:search].to_s.strip
      resources = Administrate::Search.new(
        SchoolImportResult.all,
        dashboard_class,
        search_term
      ).run
      resources = apply_collection_includes(resources)
      resources = order.apply(resources)
      resources = resources.page(params[:_page]).per(records_per_page)

      # Batch load user info to avoid N+1 queries
      user_ids = resources.filter_map(&:user_id).uniq
      RequestStore.store[:user_info_cache] = fetch_users_batch(user_ids)

      page = Administrate::Page::Collection.new(dashboard, order: order)

      render locals: {
        resources: resources,
        search_term: search_term,
        page: page,
        show_search_bar: show_search_bar?
      }
    end

    def show
      respond_to do |format|
        format.html do
          render locals: {
            page: Administrate::Page::Show.new(dashboard, requested_resource)
          }
        end
        format.csv do
          send_data generate_csv(requested_resource),
                    filename: "school_import_#{requested_resource.job_id}_#{Date.current.strftime('%Y-%m-%d')}.csv",
                    type: 'text/csv'
        end
      end
    end

    def new
      @error_details = flash[:error_details]
      render locals: {
        page: Administrate::Page::Form.new(dashboard, SchoolImportResult.new)
      }
    end

    def create
      if params[:csv_file].blank?
        flash[:error] = 'CSV file is required'
        redirect_to new_admin_school_import_result_path
        return
      end

      # Call the same service that the API endpoint uses, ensuring all validation is applied
      result = School::ImportBatch.call(
        csv_file: params[:csv_file],
        current_user: current_user
      )

      if result.success?
        flash[:notice] = "Import job started successfully. Job ID: #{result[:job_id]}"
        redirect_to admin_school_import_results_path
      else
        # Display error inline on the page
        flash.now[:error] = format_error_message(result[:error])
        @error_details = extract_error_details(result[:error])
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, SchoolImportResult.new)
        }
      end
    end

    private

    def default_sorting_attribute
      :created_at
    end

    def default_sorting_direction
      :desc
    end

    def format_error_message(error)
      return error.to_s unless error.is_a?(Hash)

      error[:message] || error['message'] || 'Import failed'
    end

    def extract_error_details(error)
      return nil unless error.is_a?(Hash)

      error[:details] || error['details']
    end

    def generate_csv(import_result)
      CSV.generate(headers: true) do |csv|
        # Header row
        csv << ['Status', 'School Name', 'School Code', 'School ID', 'Owner Email', 'Error Code', 'Error Message']

        results = import_result.results
        successful = results['successful'] || []
        failed = results['failed'] || []

        # Successful schools
        successful.each do |school|
          csv << [
            'Success',
            school['name'],
            school['code'],
            school['id'],
            school['owner_email'],
            '',
            ''
          ]
        end

        # Failed schools
        failed.each do |school|
          csv << [
            'Failed',
            school['name'],
            '',
            '',
            school['owner_email'],
            school['error_code'],
            school['error']
          ]
        end
      end
    end

    def fetch_users_batch(user_ids)
      return {} if user_ids.empty?

      users = UserInfoApiClient.fetch_by_ids(user_ids)
      users.index_by do |user|
        user[:id]
      end
    rescue StandardError => e
      Rails.logger.error("Failed to batch fetch user info: #{e.message}")
      {}
    end
  end
end

# frozen_string_literal: true

module Admin
  module NPQ
    module Applications
      class EligibilityStatusController < Admin::BaseController
        StatusOption = Struct.new(:value, :label)

        skip_after_action :verify_authorized
        skip_after_action :verify_policy_scoped

        def edit
          @status_options = [
            StatusOption.new(:marked_ineligible_by_policy, "Not eligible for funding"),
            StatusOption.new(:awaiting_more_information, "Awaiting more information"),
            StatusOption.new(:re_register, "Needs to re-register"),
          ]

          @npq_application = NPQApplication.find(params[:id])
        end

        def update
          npq_application = NPQApplication.find(params[:id])
          npq_application.assign_attributes(eligiblity_status_params)

          if npq_application.save
            name = npq_application.participant_identity.user.full_name

            flash[:success] = {
              title: "#{name} updated",
              content: "#{name} has been marked '#{npq_application.funding_eligiblity_status_code.humanize.downcase}'",
            }
            redirect_to admin_npq_applications_edge_case_path(npq_application)
          else
            flash[:alert] = {
              title: "#{name} not updated",
              content: "#{name} failed to update",
            }

            render(:edit)
          end
        end

      private

        def eligiblity_status_params
          params.require(:npq_application).permit(:funding_eligiblity_status_code)
        end
      end
    end
  end
end

module SupportInterface
  class CommandLineController < SupportInterfaceController
    def index; end

    def new
      @task = Task.new
    end

    def create
      @task = Task.new task_params

      if @task.save
        flash[:success] = 'Task created successfully'
        redirect_to action: :index
      else
        render :new
      end
    end

    def task_params
      params.require(:support_interface_task)
        .permit(:code)
    end
  end
end

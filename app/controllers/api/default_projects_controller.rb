# frozen_string_literal: true

module Api
  class DefaultProjectsController < ApiController
    before_action :require_oauth_user, only: %i[create]
    include 'phrase_identifier'

    def show
      data = if params[:type] == 'html'
               html_project
             else
               python_project
             end
      render json: data
    end

    def python
      render json: python_project
    end

    def html
      render json: html_project
    end

    def create
      identifier = PhraseIdentifier.generate
      @project = Project.new(:identifier, project_type: 'python')
      @project.components << Component.new(python_component)
      @project.save

      render '/api/projects/show', status: :created
    end

    private

    def python_component
      { extension: 'py', name: 'main', content: "import turtle\nt = turtle.Turtle()\nt.forward(100)" }
    end

    def python_project
      {
        type: 'python',
        components: [
          { lang: 'py', name: 'main',
            content: "import turtle\nt = turtle.Turtle()\nt.forward(100)\nprint(\"Oh yeah!\")" }
        ]
      }
    end

    def html_project
      content = <<~CON
        <html>\n  <head>\n    <link rel="stylesheet" type="text/css" href="style.css">\n
          </head> <body>\n    <h1>Heading</h1>\n    <p>Paragraph</p>\n  </body>\n</html>
      CON

      {
        type: 'html',
        components: [
          { lang: 'html', name: 'index', :content },
          { lang: 'css', name: 'style', content: "h1 {\n  color: blue;\n}" },
          { lang: 'css', name: 'test', content: "p {\n  background-color: red;\n}" }
        ]
      }
    end
  end
end

namespace :projects do
  desc "Import starter projects"
  task create_starter: :environment do

    projects = [
      {
        identifier: "python-hello-starter",
        name: "Hello 🌍🌎🌏",
        components: ["hello_starter.py", "emoji.py", "noemoji.py"],
        main_component: "hello_starter.py"
      },
      {
        identifier: "python-hello-example",
        name: "Hello 🌍🌎🌏 Example",
        components: ["hello_example.py", "emoji.py", "noemoji.py"],
        main_component: "hello_example.py"
      },
      {
        identifier: "python-archery-starter",
        name: "Target Practice",
        components: ["archery_starter.py"],
        main_component: "archery_starter.py"
      },
      {
        identifier: "python-archery-example",
        name: "Target Practice Example",
        components: ["archery_example.py"],
        main_component: "archery_example.py"
      }
    ]

    projects.each do |project|
      Project.find_by( identifier: project[:identifier] )&.destroy
      new_project = Project.new(identifier: project[:identifier], name: project[:name])
      project[:components].each do |component|
        file = File.open(File.dirname(__FILE__) + "/project_components/#{component}")
        component_code = file.read
        file.close
        component_name = component.split('.')[0]
        component_name = (component == project[:main_component]) ? "main" : component_name
        component_extension = component.split('.').drop(1).join('.')
        new_project.components << Component.new( name: component_name, extension: component_extension, content: component_code )
      end
      new_project.save
    end
  end
end

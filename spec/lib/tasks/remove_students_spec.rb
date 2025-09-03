# frozen_string_literal: true

require 'rails_helper'
require 'rake'
require 'tempfile'

RSpec.describe 'remove_students', type: :task do
  describe ':run' do
    let(:task) { Rake::Task['remove_students:run'] }
    let(:school) { create(:school) }
    let(:student_1) { create(:student, school: school) }
    let(:student_2) { create(:student, school: school) }
    let(:mock_service) { instance_double(StudentRemovalService) }

    before do
      # Clear the task to avoid "already invoked" errors
      task.reenable

      # Mock the confirmation input to avoid interactive prompts
      allow($stdin).to receive(:gets).and_return("yes\n")

      # Mock StudentRemovalService to avoid actual student removal
      allow(StudentRemovalService).to receive(:new).and_return(mock_service)
      allow(mock_service).to receive(:remove_student)

      # Silence console output during tests
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:print)
      allow(Rails.logger).to receive(:error)
    end

    describe 'envvar validation' do
      it 'exits when SCHOOL_ID is missing' do
        expect { task.invoke }.to raise_error(SystemExit)
      end

      it 'exits when school is not found' do
        ENV['SCHOOL_ID'] = 'non-existent-id'

        expect { task.invoke }.to raise_error(SystemExit)
      ensure
        ENV.delete('SCHOOL_ID')
      end

      it 'exits when neither CSV nor STUDENTS is provided' do
        ENV['SCHOOL_ID'] = school.id

        expect { task.invoke }.to raise_error(SystemExit)
      ensure
        ENV.delete('SCHOOL_ID')
      end
    end

    describe 'CSV handling' do
      let(:csv_file) { Tempfile.new(['students', '.csv']) }

      before do
        ENV['SCHOOL_ID'] = school.id
      end

      after do
        csv_file.close
        csv_file.unlink
        ENV.delete('SCHOOL_ID')
        ENV.delete('CSV')
      end

      it 'exits when CSV file does not exist' do
        ENV['CSV'] = '/non/existent/file.csv'

        expect { task.invoke }.to raise_error(SystemExit)
      end

      it 'processes valid CSV file' do
        csv_file.write("user_id\n#{student_1.id}\n#{student_2.id}\n")
        csv_file.rewind
        ENV['CSV'] = csv_file.path

        expect { task.invoke }.not_to raise_error
        expect(mock_service).to have_received(:remove_student).with(student_1.id)
        expect(mock_service).to have_received(:remove_student).with(student_2.id)
      end
    end

    describe 'STUDENTS handling' do
      before do
        ENV['SCHOOL_ID'] = school.id
      end

      after do
        ENV.delete('SCHOOL_ID')
        ENV.delete('STUDENTS')
      end

      it 'processes csv student list' do
        ENV['STUDENTS'] = "#{student_1.id}, #{student_2.id}"

        expect { task.invoke }.not_to raise_error
        expect(mock_service).to have_received(:remove_student).with(student_1.id)
        expect(mock_service).to have_received(:remove_student).with(student_2.id)
      end
    end

    describe 'user confirmation' do
      before do
        ENV['SCHOOL_ID'] = school.id
        ENV['STUDENTS'] = student_1.id
      end

      after do
        ENV.delete('SCHOOL_ID')
        ENV.delete('STUDENTS')
      end

      it 'exits when user does not confirm' do
        allow($stdin).to receive(:gets).and_return("no\n")

        expect { task.invoke }.to raise_error(SystemExit)
        expect(mock_service).not_to have_received(:remove_student)
      end

      it 'proceeds when user confirms with "yes"' do
        allow($stdin).to receive(:gets).and_return("yes\n")

        expect { task.invoke }.not_to raise_error
        expect(mock_service).to have_received(:remove_student).with(student_1.id)
      end
    end
  end
end

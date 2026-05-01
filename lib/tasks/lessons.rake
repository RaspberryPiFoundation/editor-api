# frozen_string_literal: true

namespace :lessons do
  desc 'Backfill cached submitted project counts for lessons'
  task backfill_submitted_projects_count: :environment do
    Lesson.connection.execute <<~SQL.squish
      WITH submitted_counts AS (
        SELECT lesson_projects.lesson_id, COUNT(*) AS submitted_projects_count
        FROM projects lesson_projects
        INNER JOIN projects remixes ON remixes.remixed_from_id = lesson_projects.id
        INNER JOIN school_projects ON school_projects.project_id = remixes.id
        INNER JOIN school_project_transitions ON school_project_transitions.school_project_id = school_projects.id
        WHERE school_project_transitions.most_recent = TRUE
          AND school_project_transitions.to_state = 'submitted'
          AND lesson_projects.lesson_id IS NOT NULL
        GROUP BY lesson_projects.lesson_id
      )
      UPDATE lessons
      SET submitted_projects_count = COALESCE(submitted_counts.submitted_projects_count, 0)
      FROM lessons target_lessons
      LEFT JOIN submitted_counts ON submitted_counts.lesson_id = target_lessons.id
      WHERE lessons.id = target_lessons.id
    SQL
  end
end

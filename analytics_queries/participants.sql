SELECT u.id                                                    as participant_id,
       pp.created_at                                           as added_at,
       sch.urn                                                 as school_urn,
       u.full_name                                             as name,
       u.email                                                 as email,
       SPLIT_PART(pp.type, '::', 2)                            as type,
       (SELECT u2.id
        FROM participant_profiles pp2
                 JOIN teacher_profiles tp2 on pp2.teacher_profile_id = tp2.id
                 JOIN users u2 on tp2.user_id = u2.id
        WHERE pp2.id = pp.mentor_profile_id)                   as mentor_id,
       c.start_year                                            as cohort,
       pp.status                                               as status,
       (SELECT state
        FROM participant_profile_states
        WHERE participant_profile_id = pp.id
        ORDER BY participant_profile_states.created_at DESC
        LIMIT 1)                                               as training_status,
       s.name                                                  as schedule,
       epvd.created_at                                         as trn_provided_at,
       (epe.status IN ('eligible', 'matched'))                 AS trn_validated,
       (epe.manually_validated OR epe.status = 'manual_check') as manual_validation_required,
       (CASE
            WHEN epe.status = 'eligible' THEN true
            WHEN epe.status = 'ineligible' THEN false
           END)                                                as eligible_for_funding
FROM participant_profiles pp
         JOIN school_cohorts sc on pp.school_cohort_id = sc.id
         JOIN cohorts c on sc.cohort_id = c.id
         JOIN schools sch on sc.school_id = sch.id
         JOIN schedules s on pp.schedule_id = s.id
         JOIN teacher_profiles tp on pp.teacher_profile_id = tp.id
         JOIN users u on tp.user_id = u.id
         LEFT OUTER JOIN ecf_participant_validation_data epvd on pp.id = epvd.participant_profile_id
         LEFT OUTER JOIN ecf_participant_eligibilities epe on pp.id = epe.participant_profile_id
WHERE pp.type IN ('ParticipantProfile::ECT', 'ParticipantProfile::Mentor')
  AND c.start_year > 2020;
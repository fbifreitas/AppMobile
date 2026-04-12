package com.appbackoffice.api.job.service;

import com.appbackoffice.api.job.entity.JobStatus;
import org.springframework.stereotype.Component;

import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

@Component
public class JobStateMachine {

    private static final Map<JobStatus, Set<JobStatus>> VALID_TRANSITIONS = Map.of(
            JobStatus.CREATED,               EnumSet.of(JobStatus.ELIGIBLE_FOR_DISPATCH),
            JobStatus.ELIGIBLE_FOR_DISPATCH, EnumSet.of(JobStatus.OFFERED, JobStatus.ACCEPTED, JobStatus.CLOSED),
            JobStatus.OFFERED,               EnumSet.of(JobStatus.ACCEPTED, JobStatus.ELIGIBLE_FOR_DISPATCH, JobStatus.CLOSED),
            JobStatus.ACCEPTED,              EnumSet.of(JobStatus.IN_EXECUTION, JobStatus.CLOSED),
            JobStatus.IN_EXECUTION,          EnumSet.of(JobStatus.FIELD_COMPLETED, JobStatus.CLOSED),
            JobStatus.FIELD_COMPLETED,       EnumSet.of(JobStatus.SUBMITTED, JobStatus.CLOSED),
            JobStatus.SUBMITTED,             EnumSet.of(JobStatus.CLOSED),
            JobStatus.CLOSED,                EnumSet.noneOf(JobStatus.class)
    );

    public void validateTransition(JobStatus from, JobStatus to) {
        Set<JobStatus> allowed = VALID_TRANSITIONS.getOrDefault(from, EnumSet.noneOf(JobStatus.class));
        if (!allowed.contains(to)) {
            throw new IllegalStateException("Transição inválida de job: " + from + " → " + to);
        }
    }

    public boolean canTransition(JobStatus from, JobStatus to) {
        return VALID_TRANSITIONS.getOrDefault(from, EnumSet.noneOf(JobStatus.class)).contains(to);
    }
}

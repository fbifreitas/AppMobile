package com.appbackoffice.api.job.entity;

public enum JobStatus {
    CREATED,
    ELIGIBLE_FOR_DISPATCH,
    OFFERED,
    ACCEPTED,
    AWAITING_SCHEDULING,
    IN_EXECUTION,
    FIELD_COMPLETED,
    SUBMITTED,
    CLOSED
}

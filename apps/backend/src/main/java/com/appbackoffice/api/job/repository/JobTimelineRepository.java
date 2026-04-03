package com.appbackoffice.api.job.repository;

import com.appbackoffice.api.job.entity.JobTimelineEntry;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface JobTimelineRepository extends JpaRepository<JobTimelineEntry, Long> {
    List<JobTimelineEntry> findByJobIdOrderByOccurredAtAsc(Long jobId);
}

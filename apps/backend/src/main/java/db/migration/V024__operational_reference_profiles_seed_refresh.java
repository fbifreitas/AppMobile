package db.migration;

import com.appbackoffice.api.intelligence.service.OperationalCaptureCatalog;
import com.appbackoffice.api.intelligence.service.OperationalReferenceProfileCodec;
import com.appbackoffice.api.intelligence.service.OperationalReferenceSeedCatalog;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.time.Instant;

public class V024__operational_reference_profiles_seed_refresh extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        OperationalCaptureCatalog captureCatalog = new OperationalCaptureCatalog();
        OperationalReferenceProfileCodec codec = new OperationalReferenceProfileCodec(new ObjectMapper());
        Connection connection = context.getConnection();

        try (PreparedStatement delete = connection.prepareStatement("""
                delete from operational_reference_profiles
                where tenant_id is null
                  and scope_type = 'GLOBAL_REFERENCE'
                  and source_type = 'SEED_BOOTSTRAP'
                """)) {
            delete.executeUpdate();
        }

        try (PreparedStatement insert = connection.prepareStatement("""
                insert into operational_reference_profiles (
                    tenant_id,
                    scope_type,
                    source_type,
                    active_flag,
                    asset_type,
                    asset_subtype,
                    refined_asset_subtype,
                    property_standard,
                    region_state,
                    region_city,
                    region_district,
                    priority_weight,
                    confidence_score,
                    candidate_subtypes_json,
                    photo_locations_json,
                    composition_json,
                    created_at,
                    updated_at
                ) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """)) {
            Timestamp now = Timestamp.from(Instant.now());
            for (OperationalReferenceSeedCatalog.SeedProfile item : OperationalReferenceSeedCatalog.globalSeedProfiles(captureCatalog)) {
                insert.setString(1, null);
                insert.setString(2, "GLOBAL_REFERENCE");
                insert.setString(3, "SEED_BOOTSTRAP");
                insert.setBoolean(4, true);
                insert.setString(5, item.assetType());
                insert.setString(6, item.assetSubtype());
                insert.setString(7, item.refinedAssetSubtype());
                insert.setString(8, item.propertyStandard());
                insert.setString(9, null);
                insert.setString(10, null);
                insert.setString(11, null);
                insert.setInt(12, item.priorityWeight());
                insert.setDouble(13, item.confidenceScore());
                insert.setString(14, codec.writeStringList(item.candidateSubtypes()));
                insert.setString(15, codec.writeStringList(item.photoLocations()));
                insert.setString(16, codec.writeComposition(item.compositionProfiles()));
                insert.setTimestamp(17, now);
                insert.setTimestamp(18, now);
                insert.addBatch();
            }
            insert.executeBatch();
        }
    }
}

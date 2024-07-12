
        CREATE TABLE IF NOT EXISTS sdsfie.STRUCTURE
        (facilityNumber character varying ,
featureDescription character varying ,
featureName character varying ,
isHeritageAsset boolean ,
mediaId character varying ,
metadataId character varying ,
propertyIdCode character varying ,
rpaConstructionType character varying ,
rpaPredomCurrentUseCatCode character varying ,
rpInterest character varying ,
rpnid character varying ,
rpsuid integer ,
rpuid character varying ,
sdsId uuid  PRIMARY KEY DEFAULT uuid_generate_v4() ,
structureIdpk character varying 
) TABLESPACE pg_default;
 
               
        ALTER TABLE IF EXISTS sdsfie.STRUCTURE
            OWNER to catalog;  
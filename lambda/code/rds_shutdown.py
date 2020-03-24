### RDS Restart - Version 1: targets specific db instances
### Works but throws error

import boto3

active_region = 'eu-west-2'

def lambda_handler(event, context):
    #Create boto3 connection to AWS
    rds_inst = boto3.client('rds', region_name=active_region)


    instanceOne='dev-int-tableau-postgres-internal-tableau-apps-test-dq'
    # instanceTwo='ext-tableau-postgres-external-tableau-apps-test-dq'
    # instanceThree='fms-postgres-fms-apps-test-dq'
    # instanceFour='int-tableau-postgres-internal-tableau-apps-test-dq'
    # instanceFive='mds-rds-mssql2012-dataingest-apps-test-dq'
    # instanceSix='postgres-datafeeds-apps-test-dq'


    print('RDS Instannces stopping...')

    shutdown1=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceOne)
    # shutdown2=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceTwo)
    # shutdown3=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceThree)
    # shutdown4=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceFour)
    # shutdown5=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceFive)
    # shutdown6=rds_inst.stop_db_instance(DBInstanceIdentifier=instanceSix)



    print('RDS Instances Stopped')

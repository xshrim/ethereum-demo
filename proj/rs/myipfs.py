import ipfsapi

api = ipfsapi.connect('192.168.103.211', 8080)
cli = ipfsapi.Client('127.0.0.1', 5001)
# res = api.ls('QmYg2AE4qScN8TcsM8Z8sLVRTerf6y7Ay6xWmnk4sNqAKr')
'''
print(cli.pin_ls(type='recursive'))

hash = cli.add_str("Hi!")
print(api.cat(hash).decode())

print(cli.pin_rm(hash))
print(cli.pin_ls(type='recursive'))
'''

print(api.cat('QmSmHtF6QPRt8PqMPKXQ32SmX4h95GyLNaMkhpMXSZWuUS'))


def run_transaction_with_retry(txn_func, session):
    while True:
        try:
            txn_func(session)  # performs transaction
            break
        except (ConnectionFailure, OperationFailure) as exc:
            # If transient error, retry the whole transaction
            if exc.has_error_label("TransientTransactionError"):
                print("TransientTransactionError, retrying " "transaction ...")
                continue
            else:
                raise


def commit_with_retry(session):
    while True:
        try:
            # Commit uses write concern set at transaction start.
            session.commit_transaction()
            print("Transaction committed.")
            break
        except (ConnectionFailure, OperationFailure) as exc:
            # Can retry commit
            if exc.has_error_label("UnknownTransactionCommitResult"):
                print("UnknownTransactionCommitResult, retrying " "commit operation ...")
                continue
            else:
                print("Error during commit ...")
                raise


# Updates two collections in a transactions


def update_employee_info(session):
    employees_coll = session.client.hr.employees
    events_coll = session.client.reporting.events

    with session.start_transaction(read_concern=ReadConcern("snapshot"), write_concern=WriteConcern(w="majority")):
        employees_coll.update_one({"employee": 3}, {"$set": {"status": "Inactive"}}, session=session)
        events_coll.insert_one({"employee": 3, "status": {"new": "Inactive", "old": "Active"}}, session=session)

        commit_with_retry(session)


# Start a session.
with client.start_session() as session:
    try:
        run_transaction_with_retry(update_employee_info, session)
    except Exception as exc:
        # Do something with error.
        raise

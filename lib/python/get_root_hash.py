from arweave.merkle import compute_root_hash
import io

def get_root_hash(data):
    return compute_root_hash(io.BytesIO(data))
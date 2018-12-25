from web3.auto import w3
from web3 import Web3
import asyncio


def handle_event(event):
    print(Web3.toText(event))
    # and whatever


async def log_loop(event_filter, poll_interval):
    while True:
        for event in event_filter.get_new_entries():
            handle_event(event)
        await asyncio.sleep(poll_interval)


def main():
    block_filter = w3.eth.filter('latest')
    tx_filter = w3.eth.filter('pending')
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(asyncio.gather(log_loop(block_filter, 2), log_loop(tx_filter, 2)))
    finally:
        loop.close()


if __name__ == '__main__':
    main()
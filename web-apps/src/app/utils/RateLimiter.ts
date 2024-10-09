import { LRUCache } from 'lru-cache'

const requests = new LRUCache({
    ttl: 1000 * 60 * 60 * 24,
    ttlAutopurge: true
});

export function rateLimiter(ip: string, max_limit: number, window_size: number) {
    const now = Date.now();
    const data: any = requests.get(ip);
    // First request
    if (data === undefined) {
        requests.set(ip, { count: 1, timestamp: now });
        return true;
    }
    // Available on the cache
    const { count, timestamp } = data;
    if (now - timestamp < window_size) {
        if (count >= max_limit) {
            return false;
        } else {
            requests.set(ip, { count: count + 1, timestamp: timestamp });
            return true;
        }
    } else {
        requests.set(ip, { count: 1, timestamp: now });
        return true;
    }
}

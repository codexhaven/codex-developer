#!/usr/bin/env python3
"""Codex Developer v12.4 -- Crypto trading research utility."""
# ctx: codexhaven
import subprocess
import sys
import json


def search_crypto_info(query):
    """Search for cryptocurrency trading information using available tools."""
    print(f"\n--- Researching: {query} ---")
    
    # Try using curl to fetch from CoinGecko API (free, no auth required)
    try:
        result = subprocess.run(
            ['curl', '-s', 'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1'],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode == 0 and result.stdout:
            data = json.loads(result.stdout)
            return {
                'status': 'success',
                'source': 'coingecko',
                'data': data,
                'count': len(data)
            }
    except (subprocess.TimeoutExpired, json.JSONDecodeError, Exception) as e:
        print(f"API fetch failed: {e}", file=sys.stderr)
    
    return {
        'status': 'fallback',
        'message': 'Use web search for detailed crypto trading research',
        'suggestion': 'Try: curl https://api.coingecko.com/api/v3/coins/bitcoin'
    }


def analyze_trading_opportunities(coin_data):
    """Analyze market data for trading opportunities."""
    if not coin_data or 'data' not in coin_data:
        return {'error': 'No data provided'}
    
    analysis = []
    for coin in coin_data['data'][:5]:
        analysis.append({
            'symbol': coin.get('symbol', '').upper(),
            'name': coin.get('name'),
            'price': coin.get('current_price'),
            'change_24h': coin.get('price_change_percentage_24h'),
            'market_cap': coin.get('market_cap'),
            'volume': coin.get('total_volume')
        })
    
    return {
        'analyzed_at': subprocess.check_output(['date', '-u', '+%Y-%m-%dT%H:%M:%SZ']).decode().strip(),
        'opportunities': analysis
    }


if __name__ == '__main__':
    query = ' '.join(sys.argv[1:]) if len(sys.argv) > 1 else 'top cryptocurrencies'
    result = search_crypto_info(query)
    print(json.dumps(result, indent=2))

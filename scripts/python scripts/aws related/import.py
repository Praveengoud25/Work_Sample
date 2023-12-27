import pandas as pd
proxy_definitions = {
    'http': 'http_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'https': 'https_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'no_proxy': '.ge.com'
}
df = pd.read_parquet('part-00000-1001baca-b457-4450-9c8b-68413cddf6b9-c000.snappy.parquet')
df.to_csv('out.csv', index=False)
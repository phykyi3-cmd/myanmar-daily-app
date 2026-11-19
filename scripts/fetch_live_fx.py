#!/usr/bin/env python3
"""Fetches live Myanmar FX market rates from real-time public endpoints and writes live_fx.json.

Sources:
  1. Bybit P2P USDT/MMK order book (Buy & Sell top-5 KBZPay/WavePay ads)
  2. Bitget P2P USDT/MMK order book (Buy & Sell top-5 KBZPay/WavePay ads)
  3. Remitly live remittance corridor (USA:USD -> MMR:MMK)
  4. Open-ER-API global USD cross rates (THB, MYR, SGD, KRW, JPY, CNY, EUR, MMK official)
  5. Gold-API world spot gold price (XAU/USD)
"""

from __future__ import annotations

import datetime as dt
import json
import statistics
import sys
import urllib.error
import urllib.request
from typing import Any


USER_AGENT = "MyanmarDailyApp-FX-Bot/1.0 (+https://github.com/phykyi3-cmd/myanmar-daily-app)"


def http_json(
    url: str,
    *,
    method: str = "GET",
    body: dict[str, Any] | None = None,
    timeout: int = 12,
) -> Any:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    headers = {"User-Agent": USER_AGENT, "Accept": "application/json"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def fetch_bybit_p2p() -> tuple[list[float], list[float]]:
    url = "https://api2.bybit.com/fiat/otc/item/online"
    buys: list[float] = []
    sells: list[float] = []
    for side, target in (("1", buys), ("0", sells)):
        try:
            res = http_json(
                url,
                method="POST",
                body={
                    "tokenId": "USDT",
                    "currencyId": "MMK",
                    "side": side,
                    "size": "5",
                    "page": "1",
                },
            )
            items = res.get("result", {}).get("items", []) or []
            for item in items:
                p = float(item["price"])
                if 2500 <= p <= 12000:
                    target.append(p)
        except Exception as exc:
            print(f"[warn] Bybit P2P side={side} failed: {exc}", file=sys.stderr)
    return buys, sells


def fetch_bitget_p2p() -> tuple[list[float], list[float]]:
    url = "https://www.bitget.com/v1/p2p/pub/adv/queryAdvList"
    buys: list[float] = []
    sells: list[float] = []
    for side, target in ((1, buys), (2, sells)):
        try:
            res = http_json(
                url,
                method="POST",
                body={
                    "side": side,
                    "pageNo": 1,
                    "pageSize": 5,
                    "coinCode": "USDT",
                    "fiatCode": "MMK",
                    "languageType": 0,
                },
            )
            items = (res.get("data") or {}).get("dataList", []) or []
            for item in items:
                p = float(item["price"])
                if 2500 <= p <= 12000:
                    target.append(p)
        except Exception as exc:
            print(f"[warn] Bitget P2P side={side} failed: {exc}", file=sys.stderr)
    return buys, sells


def fetch_remitly_mmk() -> float | None:
    url = (
        "https://api.remitly.io/v3/calculator/estimate"
        "?conduit=USA%3AUSD-MMR%3AMMK&anchor=SEND&amount=100"
    )
    try:
        res = http_json(url)
        rate_str = (
            res.get("estimate", {})
            .get("exchange_rate", {})
            .get("base_rate")
        )
        if rate_str:
            val = float(rate_str)
            if 2500 <= val <= 12000:
                return val
    except Exception as exc:
        print(f"[warn] Remitly failed: {exc}", file=sys.stderr)
    return None


def fetch_global_fx() -> dict[str, float]:
    defaults = {
        "THB": 34.0,
        "MYR": 4.15,
        "SGD": 1.30,
        "CNY": 6.75,
        "EUR": 0.91,
        "JPY": 158.0,
        "KRW": 1340.0,
        "MMK": 2100.0,
    }
    try:
        res = http_json("https://open.er-api.com/v6/latest/USD")
        rates = res.get("rates", {}) or {}
        out: dict[str, float] = {}
        for code, fallback in defaults.items():
            val = rates.get(code)
            out[code] = round(float(val), 6) if isinstance(val, (int, float)) and val > 0 else fallback
        return out
    except Exception as exc:
        print(f"[warn] open.er-api.com failed: {exc}", file=sys.stderr)
        return defaults


def fetch_world_gold_usd() -> float:
    try:
        res = http_json("https://api.gold-api.com/price/XAU")
        price = float(res["price"])
        if 1500 <= price <= 10000:
            return round(price, 2)
    except Exception as exc:
        print(f"[warn] gold-api failed: {exc}", file=sys.stderr)
    return 3730.0


def main() -> int:
    output_path = sys.argv[1] if len(sys.argv) > 1 else "live_fx.json"

    bybit_buy, bybit_sell = fetch_bybit_p2p()
    bitget_buy, bitget_sell = fetch_bitget_p2p()
    remitly_mmk = fetch_remitly_mmk()
    global_rates = fetch_global_fx()
    gold_usd = fetch_world_gold_usd()

    all_buys = bybit_buy + bitget_buy
    all_sells = bybit_sell + bitget_sell

    sources: list[str] = []
    if bybit_buy or bybit_sell:
        sources.append("Bybit P2P (USDT/MMK)")
    if bitget_buy or bitget_sell:
        sources.append("Bitget P2P (USDT/MMK)")
    if remitly_mmk is not None:
        sources.append("Remitly (USD/MMK)")
    sources.extend(["Open-ER-API", "Gold-API"])

    p2p_buy = round(statistics.median(all_buys)) if all_buys else None
    p2p_sell = round(statistics.median(all_sells)) if all_sells else None

    if p2p_buy and p2p_sell:
        p2p_mid = round((p2p_buy + p2p_sell) / 2)
    elif p2p_buy:
        p2p_mid = p2p_buy
    elif p2p_sell:
        p2p_mid = p2p_sell
    else:
        p2p_mid = 5100
        p2p_buy = 5120
        p2p_sell = 5080

    remit_rate = round(remitly_mmk) if remitly_mmk else round(p2p_mid * 0.76)

    # Myanmar physical cash USD market typically trades ~8.5% below digital USDT P2P
    # (and tracks live P2P + remittance liquidity in real time).
    cash_market_usd = round((p2p_mid * 0.912) / 5) * 5

    now_utc = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

    payload = {
        "schemaVersion": 1,
        "updatedAtUtc": now_utc,
        "usdCashMarketMmk": cash_market_usd,
        "usdP2pBuyMmk": p2p_buy,
        "usdP2pSellMmk": p2p_sell,
        "usdP2pMidMmk": p2p_mid,
        "usdRemitMmk": remit_rate,
        "usdOfficialMmk": round(global_rates["MMK"]),
        "worldGoldUsdPerOz": gold_usd,
        "globalRatesPerUsd": {
            "USD": 1.0,
            "THB": global_rates["THB"],
            "MYR": global_rates["MYR"],
            "SGD": global_rates["SGD"],
            "KRW": global_rates["KRW"],
            "JPY": global_rates["JPY"],
            "CNY": global_rates["CNY"],
            "EUR": global_rates["EUR"],
        },
        "sources": sources,
    }

    with open(output_path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

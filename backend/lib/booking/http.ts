import { NextResponse } from 'next/server';

export const jsonError = (msg: string, status: number) =>
  NextResponse.json({ error: msg }, { status });

export const isYMD = (s: string) => /^\d{4}-\d{2}-\d{2}$/.test(s ?? '');
export const isHHMM = (s: string) => /^\d{2}:\d{2}$/.test(s ?? '');
export const isEmail = (s: string) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s ?? '');

export const str = (v: unknown, max: number): string =>
  typeof v === 'string' ? v.trim().slice(0, max) : '';

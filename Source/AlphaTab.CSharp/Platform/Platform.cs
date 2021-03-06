﻿using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using AlphaTab.IO;
using AlphaTab.Util;

namespace AlphaTab.Platform
{
    internal static partial class Platform
    {
        public static T As<T>(this object s)
        {
            return (T)s;
        }

        public static void Log(LogLevel logLevel, string category, string msg, object details = null)
        {
            Trace.WriteLine($"[AlphaTab][{category}][{logLevel}] {msg} {details}", "AlphaTab");
        }

        public static float ParseFloat(string s)
        {
            float f;
            if (!float.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out f))
            {
                f = float.NaN;
            }

            return f;
        }

        public static float Log2(float s)
        {
            return (float)Math.Log(s, 2);
        }

        public static int ParseInt(string s)
        {
            float f;
            if (!float.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out f))
            {
                return int.MinValue;
            }

            return (int)f;
        }

        public static int[] CloneArray(int[] array)
        {
            return (int[])array.Clone();
        }

        public static void BlockCopy(byte[] src, int srcOffset, byte[] dst, int dstOffset, int count)
        {
            Buffer.BlockCopy(src, srcOffset, dst, dstOffset, count);
        }

        public static bool IsNullOrWhiteSpace(this string s)
        {
            return string.IsNullOrWhiteSpace(s);
        }

        public static string StringFromCharCode(int c)
        {
            return ((char)c).ToString();
        }

        public static void Foreach<T>(IEnumerable<T> e, Action<T> c)
        {
            foreach (var t in e)
            {
                c(t);
            }
        }

        public static byte[] StringToByteArray(string contents)
        {
            return Encoding.UTF8.GetBytes(contents);
        }

        public static sbyte ReadSignedByte(this IReadable readable)
        {
            return unchecked((sbyte)(byte)readable.ReadByte());
        }

        public static string ToString(byte[] data, string encoding)
        {
            var detectedEncoding = DetectEncoding(data);
            if (detectedEncoding != null)
            {
                encoding = detectedEncoding;
            }

            if (encoding == null)
            {
                encoding = "utf-8";
            }

            Encoding enc;
            try
            {
                enc = Encoding.GetEncoding(encoding);
            }
            catch
            {
                enc = Encoding.UTF8;
            }

            return enc.GetString(data, 0, data.Length);
        }

        public static bool InstanceOf<T>(object value)
        {
            return value is T;
        }

        public static string NewGuid()
        {
            return Guid.NewGuid().ToString();
        }

        public static bool IsException<T>(Exception e)
        {
            return e is T;
        }

        private static readonly Random Rnd = new Random();

        public static int Random(int max)
        {
            return Rnd.Next(max);
        }

        public static double RandomDouble()
        {
            return Rnd.NextDouble();
        }

        public static double ToDouble(byte[] bytes)
        {
            return BitConverter.ToDouble(bytes, 0);
        }

        public static float ToFloat(byte[] bytes)
        {
            return BitConverter.ToSingle(bytes, 0);
        }

        public static void ClearIntArray(int[] array)
        {
            Array.Clear(array, 0, array.Length);
        }

        public static void ClearShortArray(short[] array)
        {
            Array.Clear(array, 0, array.Length);
        }

        public static void ArrayCopy<T>(T[] src, int srcOffset, T[] dst, int dstOffset, int count)
        {
            Array.Copy(src, srcOffset, dst, dstOffset, count);
        }

        public static void Reverse(byte[] array)
        {
            Array.Reverse(array);
        }

        public static long GetCurrentMilliseconds()
        {
            return Stopwatch.GetTimestamp();
        }

        public static Action Throttle(Action action, int delay)
        {
            CancellationTokenSource cancellationTokenSource = null;
            return () =>
            {
                cancellationTokenSource?.Cancel();
                cancellationTokenSource = new CancellationTokenSource();

                Task.Run(async () =>
                    {
                        await Task.Delay(delay, cancellationTokenSource.Token);
                        action();
                    },
                    cancellationTokenSource.Token);
            };
        }
    }
}

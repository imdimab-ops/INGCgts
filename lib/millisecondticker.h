/* MilliSecondTicker кастомный класс тиккера в msec для оси customPlot->xAxis */

#ifndef MILLISECONDTICKER_H
#define MILLISECONDTICKER_H

#include <QDateTime>
#include "qcustomplot.h"


class MilliSecondTicker : public QCPAxisTicker
{
public:
    MilliSecondTicker()
    {
        setTickCount(6); //QCPAxisTickerDateTime использует 6 по умолчанию
        mDateStrategy = dsNone;
    }

    QString getTickLabel(double tick, const QLocale &locale, QChar formatChar, int precision) override
    {
        Q_UNUSED(locale)
        Q_UNUSED(formatChar)
        Q_UNUSED(precision)

        QDateTime dt = QDateTime::fromMSecsSinceEpoch(static_cast<qint64>(tick));

        //Выбираем формат в зависимости от стратегии
        switch (mDateStrategy) {
        case dsUniformDayInMonth:
            return dt.toString("dd.MM");
        case dsUniformTimeInDay:
            return dt.toString("hh:mm");
        default:
            return dt.toString("hh:mm:ss");
        }
    }

    double getTickStep(const QCPRange &range) override
    {
        double result = range.size() / double(mTickCount + 1e-10);
        mDateStrategy = dsNone;

        //Переводим в секунды для сравнения (как в оригинале)
        double resultInSeconds = result / 1000.0;

        if (resultInSeconds < 1) //меньше 1 секунды
        {
            //Используем cleanMantissa в миллисекундах
            result = cleanMantissa(result);
        }
        else if (resultInSeconds < 86400*30.4375*12) // меньше года (в секундах)
        {
            //Подбираем ближайшее значение из списка (значения в секундах)
            double secondsStep = pickClosest(resultInSeconds, QVector<double>()
                                                                  << 1 << 2.5 << 5 << 10 << 15 << 30 << 60 << 2.5*60 << 5*60 << 10*60 << 15*60 << 30*60 << 60*60
                                                                  << 3600*2 << 3600*3 << 3600*6 << 3600*12 << 3600*24
                                                                  << 86400*2 << 86400*5 << 86400*7 << 86400*14 << 86400*30.4375
                                                                  << 86400*30.4375*2 << 86400*30.4375*3 << 86400*30.4375*6 << 86400*30.4375*12);

            //Конвертируем обратно в миллисекунды
            result = secondsStep * 1000.0;

            //Устанавливаем стратегию для форматирования
            if (secondsStep > 86400*30.4375 - 1) //месячные интервалы
                mDateStrategy = dsUniformDayInMonth;
            else if (secondsStep > 3600*24 - 1) //дневные интервалы
                mDateStrategy = dsUniformTimeInDay;
        }
        else //больше года
        {
            const double millisecondsPerYear = 86400.0 * 30.4375 * 12 * 1000.0; //с учетом високосных лет
            result = cleanMantissa(result / millisecondsPerYear) * millisecondsPerYear;
            mDateStrategy = dsUniformDayInMonth;
        }

        return result;
    }

    int getSubTickCount(double tickStep) override
    {
        double stepInSeconds = tickStep / 1000.0;
        int result = QCPAxisTicker::getSubTickCount(stepInSeconds);

        //Аналогично QCPAxisTickerDateTime::getSubTickCount
        switch (qRound(stepInSeconds))
        {
        case 5*60: result = 4; break;
        case 10*60: result = 1; break;
        case 15*60: result = 2; break;
        case 30*60: result = 1; break;
        case 60*60: result = 3; break;
        case 3600*2: result = 3; break;
        case 3600*3: result = 2; break;
        case 3600*6: result = 1; break;
        case 3600*12: result = 3; break;
        case 3600*24: result = 3; break;
        case 86400*2: result = 1; break;
        case 86400*5: result = 4; break;
        case 86400*7: result = 6; break;
        case 86400*14: result = 1; break;
        case int(86400*30.4375+0.5): result = 3; break;
        case int(86400*30.4375*2+0.5): result = 1; break;
        case int(86400*30.4375*3+0.5): result = 2; break;
        case int(86400*30.4375*6+0.5): result = 5; break;
        case int(86400*30.4375*12+0.5): result = 3; break;
        }
        return result;
    }

private:
    enum DateStrategy { dsNone, dsUniformTimeInDay, dsUniformDayInMonth };
    DateStrategy mDateStrategy;

    // Вспомогательные методы из QCPAxisTicker
    double cleanMantissa(double input) const
    {
        double magnitude = qPow(10.0, qFloor(qLn(input)/qLn(10.0)));
        double mantissa = input/magnitude;
        if (mantissa < 1.5)
            return magnitude*1.0;
        if (mantissa < 2.5)
            return magnitude*2.0;
        if (mantissa < 4.0)
            return magnitude*2.5;
        if (mantissa < 6.0)
            return magnitude*4.0;
        if (mantissa < 8.0)
            return magnitude*5.0;
        return magnitude*10.0;
    }

    double pickClosest(double target, const QVector<double> &candidates) const
    {
        if (candidates.isEmpty())
            return target;

        int bestIndex = 0;
        double bestDiff = qAbs(candidates[0] - target);

        for (int i = 1; i < candidates.size(); ++i)
        {
            double diff = qAbs(candidates[i] - target);
            if (diff < bestDiff)
            {
                bestDiff = diff;
                bestIndex = i;
            }
        }
        return candidates[bestIndex];
    }
};

#endif // MILLISECONDTICKER_H

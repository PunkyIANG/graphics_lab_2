import std.stdio;
import arsd.simpledisplay;
import std.algorithm;
import std.conv;

void main()
{
    const int width = 1280;
    const int height = 720;
    const int padding = 60;

    const graphHeight = 500;
    const barWidth = 25;
    const barPadding = 20;

    const int[] legend = [2014, 2015, 2016, 2017, 2018, 2019, 2020];
    const int[][] graphData = [
        [4187, 4209, 4080, 3708, 4223, 4857, 2875],
        [2374, 2236, 2507, 2111, 2243, 3660, 1607]
    ];
    const string[] legendText = ["Emigranti", "Imigranti"];
    const Color[] colorArr = [Color.blue, Color.red];
    const Color[] diagColorArr = [
        Color.brown, Color.green, Color.magenta, Color.teal, Color.yellow,
        Color.blue, Color.red
    ];
    const Point ortho = Point(-15, 10);
    const ubyte shadeAmount = 96;

    static OperatingSystemFont font = null;
    const int fontSize = 15;
    font = new OperatingSystemFont("Arial", fontSize);

    const int diagWidth = 500;
    const int diagHeight = 300;
    const int arcMax = 23040;
    const Point diagOrtho = Point(0, 40);

    foreach (const(int[]) line; graphData)
    {
        assert(legend.length == line.length);
    }

    int numCount = -1;
    int division = 1;
    int maxDivisionValue = 0;

    // calculate division stuff
    {
        int maxValue = 0;

        foreach (const(int[]) line; graphData)
            maxValue = max(maxValue, line.maxElement);

        int temp = maxValue;

        while (temp != 0)
        {
            temp /= 10;
            numCount++;
        }

        for (int i = 0; i < numCount; i++)
            division *= 10;

        while (maxDivisionValue < maxValue)
            maxDivisionValue += division;

        printf("%i", maxDivisionValue);
    }

    int DataToPixels(int data)
    {
        return data * graphHeight / maxDivisionValue;
    }

    auto window = new SimpleWindow(width, height);
    {
        auto painter = window.draw();
        painter.setFont(font);
        painter.outlineColor = Color.white;
        painter.drawRectangle(Point(0, 0), Point(width, height));

        painter.outlineColor = Color.gray;
        painter.fillColor = Color.white;

        // 2d graph prototype
        Point graphTopLeft = Point(padding, padding);
        Point graphOrigin = Point(padding, padding + graphHeight);
        Point graphBottomRight = graphOrigin + Point(cast(int)(
                graphData.length * legend.length * barWidth + (legend.length + 1) * barPadding), 0);
        {
            painter.drawRectangle(graphTopLeft, graphBottomRight);

            int tempDivision = division;
            do
            {
                painter.drawLine(graphOrigin + Point(0, -DataToPixels(tempDivision)),
                        graphBottomRight + Point(0, -DataToPixels(tempDivision)));
                tempDivision += division;
            }
            while (tempDivision < maxDivisionValue);

            int sectionWidth = cast(int)(barPadding + barWidth * graphData.length);

            painter.outlineColor = Color.black;

            for (int j = 0; j < graphData.length; j++)
            {
                painter.fillColor = colorArr[j];
                for (int i = 0; i < legend.length; i++)
                {
                    painter.drawRectangle(graphOrigin + Point(barPadding + i * sectionWidth + j * barWidth,
                            -DataToPixels(graphData[j][i])),
                            graphOrigin + Point(barPadding + i * sectionWidth + (j + 1) * barWidth,
                                0));
                }
            }
        }

        // 3d stuff
        {
            painter.outlineColor = Color.gray;
            painter.fillColor = Color.white;

            painter.drawLine(graphTopLeft + ortho, graphOrigin + ortho);
            painter.drawLine(graphOrigin + ortho, graphBottomRight + ortho);

            int tempDivision = 0;
            do
            {
                painter.outlineColor = Color.gray;
                auto startPoint = graphOrigin + Point(0, -DataToPixels(tempDivision));
                painter.drawLine(startPoint, startPoint + ortho);

                painter.outlineColor = Color.black;
                painter.drawText(startPoint - Point(padding, 0), to!string(tempDivision));
                tempDivision += division;
            }
            while (tempDivision <= maxDivisionValue);

            painter.fillColor = Color.gray;
            painter.outlineColor = Color.gray;
            painter.drawPolygon([
                    graphOrigin, graphBottomRight, graphBottomRight + ortho,
                    graphOrigin + ortho
                    ]);

            int sectionWidth = cast(int)(barPadding + barWidth * graphData.length);

            painter.outlineColor = Color.black;
            for (int j = 0; j < graphData.length; j++)
            {
                painter.fillColor = colorArr[j];

                for (int i = 0; i < legend.length; i++)
                {
                    painter.drawRectangle(graphOrigin + Point(barPadding + i * sectionWidth + j * barWidth,
                            -DataToPixels(graphData[j][i])) + ortho,
                            graphOrigin + Point(barPadding + i * sectionWidth + (j + 1) * barWidth,
                                0) + ortho);

                    if (j == 0)
                        painter.drawText(graphOrigin + Point(barPadding + i * sectionWidth + j * barWidth,
                                0) + ortho, to!string(legend[i]));
                }

                Color newCol = Color.black;
                newCol.a = shadeAmount;
                painter.fillColor = colorArr[j].alphaBlend(newCol);

                for (int i = 0; i < legend.length; i++)
                {
                    int barSpacing = barPadding + i * sectionWidth + j * barWidth;

                    auto startPointTop = graphOrigin + Point(barSpacing,
                            -DataToPixels(graphData[j][i])) + ortho;

                    painter.drawPolygon([
                            startPointTop, startPointTop + Point(barWidth, 0),
                            startPointTop + Point(barWidth, 0) - ortho,
                            startPointTop - ortho,
                            ]);

                    auto startPointBot = graphOrigin + Point(barSpacing + barWidth, 0) + ortho;

                    painter.drawPolygon([
                            startPointBot, startPointBot - ortho,
                            startPointTop + Point(barWidth, 0) - ortho,
                            startPointTop + Point(barWidth, 0),
                            ]);
                }
            }

            for (int i = 0; i < legendText.length; i++)
            {
                painter.fillColor = colorArr[i];
                painter.drawRectangle(graphOrigin + Point(0,
                        padding + i * fontSize), Size(fontSize - 2, fontSize - 2));
                painter.drawText(graphOrigin + Point(fontSize, padding + i * fontSize),
                        legendText[i]);

            }
        }

        // diagram stuff
        {
            auto diagTop = graphBottomRight + Point(padding, -graphHeight);

            // painter.fillColor = Color.white;
            // painter.drawEllipse(diagTop + diagOrtho,
            //         diagTop + diagOrtho + Point(diagWidth, diagHeight));

            // painter.outlineColor = Color.white;
            // painter.drawRectangle(diagTop + diagOrtho,
            //         diagTop + diagOrtho + Point(diagWidth, diagHeight / 2));

            // painter.outlineColor = Color.black;
            // painter.drawLine(diagTop + Point(0, diagHeight / 2),
            //         diagTop + Point(0, diagHeight / 2) + diagOrtho);

            // painter.drawLine(diagTop + Point(diagWidth, diagHeight / 2),
            //         diagTop + Point(diagWidth, diagHeight / 2) + diagOrtho);

            int[] DataToRads(int[] data)
            {
                int sum = data.sum;

                int[] res = new int[data.length + 1];
                res[0] = 0;
                res[data.length] = arcMax;

                for (int i = 1; i < data.length; i++)
                    res[i] = res[i - 1] + cast(int)(cast(float) data[i - 1] * arcMax / sum);

                res[] += arcMax / 4;

                return res;
            }

            auto dataSum = new int[graphData[0].length];

            for (int j = 0; j < graphData[0].length; j++)
                for (int i = 0; i < graphData.length; i++)
                    dataSum[j] += graphData[i][j];

            auto arcData = DataToRads(dataSum);

            for (int offset = diagOrtho.y; offset >= 0; offset--)
            {
                if (offset == 0 || offset == diagOrtho.y)
                    painter.outlineColor = Color.black;
                else
                    painter.outlineColor = Color.transparent;

                for (int i = 0; i < arcData.length - 1; i++)
                {
                    if ((arcData[i] < arcMax / 2) && (arcData[i + 1] < arcMax / 2) && (offset != 0))
                        continue;

                    painter.fillColor = diagColorArr[i];
                    painter.drawArc(diagTop + Point(0, offset), diagWidth,
                            diagHeight, arcData[i], arcData[i + 1]);
                }
            }

            Point diagLegendTop = diagTop + Point(0, diagHeight + padding);

            for (int i = 0; i < legend.length; i++) {
                painter.fillColor = diagColorArr[i];
                painter.drawRectangle(diagLegendTop + Point(0, i * fontSize), Size(fontSize - 2, fontSize - 2));
                painter.drawText(diagLegendTop + Point(fontSize, i * fontSize), to!string(legend[i]));

            }

        }
    }

    window.eventLoop(0, // the 0 is a timer if you want approximate frames
            delegate(KeyEvent ke) {
        // key pressed or released
    }, delegate(dchar character) {
        // character pressed
    }, delegate(MouseEvent me) {
        // mouse moved or clicked
    });

}

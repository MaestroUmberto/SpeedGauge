#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QCommandLineParser>
#include "qconsolelistener.h"

#include <memory>
#include <iomanip>

class MyApp
{
    private:
    static constexpr unsigned int MaxAllowedSpeedValue = 200;
    static constexpr double DataInputIntervalSeconds = 0.05; // 50ms = 0.05s

    QGuiApplication& QGuiApp;
    QQmlApplicationEngine& QQmlAppEngine;
    std::unique_ptr<QCommandLineParser> QCmdLineParser;
    std::unique_ptr<QConsoleListener> QConListener;
    std::unique_ptr<QObject> MySpeedGauge;

    bool CLI{false};

    unsigned int DataSamplesNumber{0};
    double TotalDistance{0}; // meters
    double AverageSpeed{0};  // meters per seconds
    std::map<unsigned int,unsigned int> HistogramData; // <speed, number of readings of a specific speed value>

    void prepareHistogramDataStorage() noexcept
    {
        // 0 - 200, 201 keys
        for(int i=0;i<MaxAllowedSpeedValue+1;i++)
            this->HistogramData[i]=0;
    }

    void parseArguments()
    {
        this->QCmdLineParser = std::make_unique<QCommandLineParser>();
        this->QCmdLineParser->addOptions({
        // A boolean option with multiple names (-n, --nogui)
        {{"n", "nogui"},QGuiApplication::translate("main", "Disable GUI mode.")},
        // An option with a value
        {{"d", "datasource"},
            QGuiApplication::translate("main", "Select source: stdin (default), sql or can."),
            QGuiApplication::translate("main", "source")},
        });

        this->QCmdLineParser->process(this->QGuiApp);
    }

    void setupGui()
    {
        const QUrl url(QStringLiteral("qrc:/main.qml"));
        QObject::connect(&this->QQmlAppEngine, &QQmlApplicationEngine::objectCreated,
                         &this->QGuiApp, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QGuiApplication::exit(-1);
        }, Qt::QueuedConnection);
        this->QQmlAppEngine.load(url);

        this->MySpeedGauge.reset(this->QQmlAppEngine.rootObjects().at(0)->findChild<QObject*>("mySpeedGauge"));
        if(!this->MySpeedGauge)
        {
            throw std::runtime_error("Unable to correctly initialize speed gauge graphical interface.");
        }
    }

    void readDataFromStdIn()
    {
        this->QConListener = std::make_unique<QConsoleListener>();
        QObject::connect(QConListener.get(), &QConsoleListener::newLine,
        [this](const QString &strNewLine) {

            bool ConversionOk = false;
            int Speed = strNewLine.toInt(&ConversionOk, 10);
            if((ConversionOk) && (Speed>0))
            {
                if(!CLI)
                {
                    QMetaObject::invokeMethod(this->MySpeedGauge.get(), "setSpeedValue",Q_ARG(int, Speed));
                }

                std::cout<<"current speed: "<<Speed<<std::endl;
                this->handleData(Speed);
            }

            // quit
            if ((strNewLine.compare("quit", Qt::CaseInsensitive) == 0)||
                (strNewLine.compare("q", Qt::CaseInsensitive) == 0))
            {
                //qDebug() << "Goodbye";
                this->Quit();
            }
        });
    }

    public:
    MyApp(QGuiApplication& QGA,QQmlApplicationEngine& QQAE)//,QConsoleListener& QCL)
        : QGuiApp(QGA), QQmlAppEngine(QQAE)
    {
        this->parseArguments();
        this->prepareHistogramDataStorage();
    }

    ~MyApp()
    {

    }

    void handleData(const double& speedValue) noexcept
    {
        this->HistogramData[speedValue]++;

        // 1 km/h = 3.6 m/s -> 1 m/s = 10/36 km/h
        this->TotalDistance+=(speedValue*10/36*this->DataInputIntervalSeconds);
        this->DataSamplesNumber++;

        // average speed = total distance / total time
        this->AverageSpeed=this->TotalDistance/(this->DataSamplesNumber*this->DataInputIntervalSeconds);

        //std::cout<<this->HistogramData.size()<<std::endl;
        //std::cout<<std::setprecision(4)<<this->TotalDistance<<std::endl;
        //std::cout<<std::setprecision(4)<<this->AverageSpeed<<std::endl;
    }

    void run()
    {
        if(!this->QCmdLineParser->isSet("nogui"))
        {
            this->setupGui();
            this->CLI = false;
        }
        else
        {
            this->CLI = true;
        }

        if(this->QCmdLineParser->isSet("datasource"))
        {
            QString dataSourceOption = this->QCmdLineParser->value("datasource");
            std::cout << dataSourceOption.toStdString()<<std::endl;

            if("stdin"==dataSourceOption)
            {
                this->readDataFromStdIn();
            }
            else if("sql"==dataSourceOption)
            {
                // readDataFromSqlDatabase();
            }
            else if("can"==dataSourceOption)
            {
                // readDataFromCanBus();
            }
            else
            {
                throw std::invalid_argument("Unexpected data source argument: "+dataSourceOption.toStdString());
            }
        }
        else
        {
            // stdin by default
            this->readDataFromStdIn();
        }
    }

    void PrintResults() noexcept
    {
        std::cout<< "Number of samples: "<<this->DataSamplesNumber<<std::endl;
        std::cout<< "Total distance:    "<<std::setprecision(4)<<(this->TotalDistance/1000)<<" km."<<std::endl;
        std::cout<< "Average speed:     "<<std::setprecision(4)<<(AverageSpeed*3.6)<<" km/h."<<std::endl;
    }

    void Quit()
    {
        this->PrintResults();
        this->MySpeedGauge.release();
        this->QGuiApp.quit();
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    MyApp MyQtApp(app,engine);

    try
    {
        MyQtApp.run();
    } catch (const std::exception& Ex) {
        std::cout<<"Exception: "<<Ex.what()<<std::endl;
        QMetaObject::invokeMethod(qApp,"quit",Qt::QueuedConnection);
    }
    return app.exec();
}

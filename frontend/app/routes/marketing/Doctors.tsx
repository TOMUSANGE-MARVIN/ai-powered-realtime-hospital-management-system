import type { Route } from "./+types/Doctors";
import PageHeader from "@/components/home/PageHeader";
import CtaBanner from "@/components/home/CtaBanner";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Doctors — Ask Musawo" },
    {
      name: "description",
      content:
        "Meet the board-certified specialists behind Ask Musawo's coordinated, AI-assisted care.",
    },
  ];
}

const DOCTORS = [
  {
    name: "Dr. Grace Nakato",
    specialty: "Internal Medicine",
    department: "Internal Medicine",
    image: "/images/doctors/dr-female-1.png",
  },
  {
    name: "Dr. Joseph Okello",
    specialty: "Pediatrics",
    department: "Pediatrics",
    image: "/images/doctors/dr-male-1.png",
    imagePosition: "left",
  },
  {
    name: "Dr. Patricia Namutebi",
    specialty: "Orthopedic Surgery",
    department: "Orthopedics",
    image: "/images/doctors/dr-female-2.png",
  },
  {
    name: "Dr. Ibrahim Wasswa",
    specialty: "Cardiology",
    department: "Cardiology",
    image: "/images/doctors/dr-male-2.png",
  },
  {
    name: "Dr. Susan Achieng",
    specialty: "Obstetrics & Gynecology",
    department: "Maternity",
    image: "/images/doctors/dr-female-3.png",
  },
  {
    name: "Dr. Sarah Nabwire",
    specialty: "Emergency Medicine",
    department: "Emergency",
    image: "/images/doctors/dr-female-4.png",
  },
];

export default function Doctors() {
  return (
    <>
      <PageHeader
        eyebrow="Meet the team"
        title={
          <>
            Specialists you
            <br />
            can trust
          </>
        }
        description="Board-certified, deeply experienced, and backed by real-time data — our specialists across every department work as one coordinated team."
      />

      <section className="bg-white pb-28">
        <div className="mx-auto grid max-w-6xl grid-cols-1 gap-8 px-6 sm:grid-cols-2 md:px-4 lg:grid-cols-3">
          {DOCTORS.map((doctor) => (
            <div key={doctor.name} className="group text-center">
              <div className="mx-auto h-64 w-full overflow-hidden rounded-[2rem] bg-stone-100 shadow-md">
                <img
                  src={doctor.image}
                  alt={doctor.name}
                  style={
                    doctor.imagePosition
                      ? { objectPosition: doctor.imagePosition }
                      : undefined
                  }
                  className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                />
              </div>
              <h3 className="font-display mt-5 text-xl font-medium text-stone-900">
                {doctor.name}
              </h3>
              <p className="mt-1 text-sm text-stone-500">{doctor.specialty}</p>
              <span className="mt-3 inline-flex items-center rounded-full bg-stone-100 px-3 py-1 text-[11px] font-semibold tracking-wide text-stone-600 uppercase">
                {doctor.department}
              </span>
            </div>
          ))}
        </div>
      </section>

      <CtaBanner />
    </>
  );
}

import type { Route } from "./+types/Doctors";
import PageHeader from "@/components/home/PageHeader";
import CtaBanner from "@/components/home/CtaBanner";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "Doctors — MedFlow AI" },
    {
      name: "description",
      content:
        "Meet the board-certified specialists behind MedFlow AI's coordinated, AI-assisted care.",
    },
  ];
}

const DOCTORS = [
  {
    name: "Dr. Grace Nakato",
    specialty: "Internal Medicine",
    department: "Internal Medicine",
    image:
      "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&q=80&auto=format&fit=crop",
  },
  {
    name: "Dr. Joseph Okello",
    specialty: "Pediatrics",
    department: "Pediatrics",
    image:
      "https://images.unsplash.com/photo-1622902046580-2b47f47f5471?w=400&q=80&auto=format&fit=crop",
  },
  {
    name: "Dr. Ronald Ssebunya",
    specialty: "Emergency Medicine",
    department: "Emergency",
    image:
      "https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&q=80&auto=format&fit=crop",
  },
  {
    name: "Dr. Patricia Namutebi",
    specialty: "Orthopedic Surgery",
    department: "Orthopedics",
    image:
      "https://images.unsplash.com/photo-1594824476967-48c8b964273f?w=400&q=80&auto=format&fit=crop",
  },
  {
    name: "Dr. Ibrahim Wasswa",
    specialty: "Cardiology",
    department: "Cardiology",
    image:
      "https://images.unsplash.com/photo-1612531386530-97286d97c2d2?w=400&q=80&auto=format&fit=crop",
  },
  {
    name: "Dr. Susan Achieng",
    specialty: "Obstetrics & Gynecology",
    department: "Maternity",
    image:
      "https://images.unsplash.com/photo-1651008376811-b90baee60c1f?w=400&q=80&auto=format&fit=crop",
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
